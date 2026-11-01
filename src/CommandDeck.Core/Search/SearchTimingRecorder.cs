namespace CommandDeck;

// How recent searches performed, for Settings → Diagnostics. Durations only;
// no query text is ever recorded.
public sealed class SearchTimingSummary
{
    public int Searches { get; init; }
    public long MedianMilliseconds { get; init; }
    public long P95Milliseconds { get; init; }
    public long MaximumMilliseconds { get; init; }
    public List<ProviderTimingSummary> Providers { get; init; } = [];
}

public sealed class ProviderTimingSummary
{
    public required string Id { get; init; }
    public int Runs { get; init; }
    public long P95Milliseconds { get; init; }
    public long MaximumMilliseconds { get; init; }
    public int Timeouts { get; init; }
}

/// <summary>
/// Keeps the durations of the most recent searches and of each provider's most
/// recent runs, and summarizes them with nearest-rank percentiles. Providers
/// are listed slowest first, so a provider that keeps hitting its deadline
/// leads the list.
/// </summary>
public sealed class SearchTimingRecorder
{
    public const int SearchCapacity = 200;
    public const int ProviderCapacity = 100;
    public const string TimeoutOutcome = "timeout";

    private readonly Lock _gate = new( );
    private readonly Queue<long> _searches = new( );
    private readonly Dictionary<string, Queue<(long Milliseconds, bool TimedOut)>> _providers = new( StringComparer.Ordinal );

    public void RecordSearch( long milliseconds )
    {
        lock ( _gate )
        {
            Enqueue( _searches, Math.Max( 0, milliseconds ), SearchCapacity );
        }
    }

    public void RecordProvider( string providerId, long milliseconds, string outcome )
    {
        ArgumentNullException.ThrowIfNull( providerId );

        lock ( _gate )
        {
            if ( !_providers.TryGetValue( providerId, out var runs ) )
            {
                runs = new( );
                _providers[providerId] = runs;
            }

            Enqueue( runs, (Math.Max( 0, milliseconds ), outcome == TimeoutOutcome), ProviderCapacity );
        }
    }

    public SearchTimingSummary Summarize( )
    {
        lock ( _gate )
        {
            var searches = _searches.Order( ).ToArray( );

            return new SearchTimingSummary
            {
                Searches = searches.Length,
                MedianMilliseconds = Percentile( searches, 0.5 ),
                P95Milliseconds = Percentile( searches, 0.95 ),
                MaximumMilliseconds = searches.Length == 0 ? 0 : searches[^1],
                Providers = _providers
                    .Select( static pair => Summarize( pair.Key, pair.Value ) )
                    .OrderByDescending( static provider => provider.P95Milliseconds )
                    .ThenBy( static provider => provider.Id, StringComparer.Ordinal )
                    .ToList( )
            };
        }
    }

    private static ProviderTimingSummary Summarize( string id, Queue<(long Milliseconds, bool TimedOut)> runs )
    {
        var durations = runs
            .Select( static run => run.Milliseconds )
            .Order( )
            .ToArray( );

        return new ProviderTimingSummary
        {
            Id = id,
            Runs = durations.Length,
            P95Milliseconds = Percentile( durations, 0.95 ),
            MaximumMilliseconds = durations.Length == 0 ? 0 : durations[^1],
            Timeouts = runs.Count( static run => run.TimedOut )
        };
    }

    // Nearest rank: the smallest value with at least that share at or below it.
    private static long Percentile( long[] sorted, double share ) =>
        sorted.Length == 0 ? 0 : sorted[Math.Clamp( ( int ) Math.Ceiling( share * sorted.Length ) - 1, 0, sorted.Length - 1 )];

    private static void Enqueue<T>( Queue<T> queue, T value, int capacity )
    {
        if ( queue.Count == capacity )
        {
            queue.Dequeue( );
        }

        queue.Enqueue( value );
    }
}
