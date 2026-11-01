namespace CommandDeck.Specs;

public static partial class Program
{
    private static void SearchTimingsSummarizeRecentSearchesAndSlowProviders( )
    {
        SearchTimingRecorder recorder = new( );
        Equal( 0, recorder.Summarize( ).Searches );
        Equal( 0L, recorder.Summarize( ).P95Milliseconds );

        foreach ( var milliseconds in Enumerable.Range( 1, 10 ) )
        {
            recorder.RecordSearch( milliseconds );
        }

        var summary = recorder.Summarize( );
        Equal( 10, summary.Searches );
        Equal( 5L, summary.MedianMilliseconds );
        Equal( 10L, summary.P95Milliseconds );
        Equal( 10L, summary.MaximumMilliseconds );

        // Only the most recent searches count.
        foreach ( var _ in Enumerable.Range( 0, SearchTimingRecorder.SearchCapacity ) )
        {
            recorder.RecordSearch( 20 );
        }

        Equal( SearchTimingRecorder.SearchCapacity, recorder.Summarize( ).Searches );
        Equal( 20L, recorder.Summarize( ).MedianMilliseconds );

        // The provider that keeps missing its deadline leads the list.
        recorder.RecordProvider( "hyprland", 5, "complete" );
        recorder.RecordProvider( "catalog", 100, "complete" );
        recorder.RecordProvider( "catalog", 350, SearchTimingRecorder.TimeoutOutcome );
        recorder.RecordProvider( "hyprland", 6, "complete" );
        recorder.RecordProvider( "catalog", 200, "complete" );

        var providers = recorder.Summarize( ).Providers;
        Equal( "catalog|hyprland", string.Join( '|', providers.Select( static provider => provider.Id ) ) );
        Equal( 3, providers[0].Runs );
        Equal( 350L, providers[0].P95Milliseconds );
        Equal( 1, providers[0].Timeouts );
        Equal( 0, providers[1].Timeouts );
    }
}
