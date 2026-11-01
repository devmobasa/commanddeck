namespace CommandDeck;

/// <summary>
/// Finds Settings from plain search: typing "transparency" or "reduce motion"
/// offers the card that holds it, and Enter opens Settings there. The rows come
/// from <see cref="SettingsIndex"/>, the same terms Settings search uses. Short
/// queries, filters, calculator, assistant, and command mode list nothing.
/// </summary>
public sealed class SettingsProvider : ICommandProvider
{
    private const string ResultPrefix = "settings:";
    private const string OpenActionId = "open";
    private const string Icon = "preferences-system";
    private const int MinimumQueryCharacters = 3;

    // Settings answer a search beside what it found; they rank below an
    // equally good application or file.
    private const double ScoreWeight = 0.9;

    public string Id => ProviderIds.Settings;

    public ValueTask<IReadOnlyList<SearchResult>> SearchAsync( ParsedQuery query, SearchRequest request, CancellationToken cancellationToken )
    {
        ArgumentNullException.ThrowIfNull( query );
        ArgumentNullException.ThrowIfNull( request );

        cancellationToken.ThrowIfCancellationRequested( );
        var text = query.Text.Trim( );
        if ( text.Length < MinimumQueryCharacters || query.IncludedFilters.Count > 0 ||
             query is { IsCalculator: true } or { IsAiMode: true } or { IsCommandMode: true } )
        {
            return ValueTask.FromResult<IReadOnlyList<SearchResult>>( [] );
        }

        List<SearchResult> results = [];
        foreach ( var entry in SettingsIndex.Entries )
        {
            var score = DesktopControlsProvider.Match( text, entry.Title, $"{entry.Keywords} {entry.Breadcrumb}" );
            if ( score > 0 )
            {
                results.Add( BuildRow( entry, score * ScoreWeight ) );
            }
        }

        return ValueTask.FromResult<IReadOnlyList<SearchResult>>( results );
    }

    public static string ResultIdFor( string settingId ) => ResultPrefix + settingId;

    private static SearchResult BuildRow( SettingEntry entry, double score )
    {
        var location = $"Settings › {entry.Breadcrumb}";

        return new SearchResult
        {
            Id = ResultIdFor( entry.Id ),
            Kind = ResultKinds.Setting,
            Title = entry.Title,
            Subtitle = location,
            Icon = Icon,
            ProviderId = ProviderIds.Settings,
            SourceId = SourceIds.Settings,
            Section = ResultSections.Settings,
            Score = score,
            Details = [new DetailField( "Description", entry.Description ), new DetailField( "Location", location )],
            Actions =
            [
                new CommandAction
                {
                    Id = OpenActionId,
                    Title = "Open in Settings",
                    Kind = ActionKinds.OpenSettings,
                    Arguments = new Dictionary<string, string>( StringComparer.Ordinal ) { [ActionArgumentNames.SettingId] = entry.Id }
                }
            ]
        };
    }
}
