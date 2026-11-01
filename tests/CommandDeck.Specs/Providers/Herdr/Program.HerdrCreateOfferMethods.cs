namespace CommandDeck.Specs;

public static partial class Program
{
    private static async Task HerdrBrowsedSpaceOffersToCreateAMissingTabAsync( )
    {
        var directory = SpecTemporaryFiles.CreateDirectory( "commanddeck-herdr-create-offer-" ).FullName;

        try
        {
            CommandDeckOptions options = new( )
            {
                Storage = new StorageOptions { DatabasePath = Path.Combine( directory, "catalog.db" ) },
                Ai = new AiOptions { Enabled = false, Providers = [] }
            };

            SqliteCatalog catalog = new( options.Storage );
            await catalog.InitializeAsync( default );
            HerdrFake fake = new( ) { Respond = TabEditResponse };
            HerdrClient client = new( fake.Runner, static ( ) => true );
            SearchCoordinator coordinator = new( [new HerdrProvider( client )], options.Search );
            await using var runtime = InvocationFixture( options, catalog, catalog.UsageHistory, new LinuxActionExecutor( herdr: client ), coordinator );

            async Task<IReadOnlyList<SearchResult>> BrowseAsync( string query, string? workspaceId = "w1" ) =>
                await runtime.SearchAsync( new SearchRequest { Query = query, HerdrWorkspaceId = workspaceId, Limit = 20 }, default );

            // A name no tab has comes last, with the dialog filled in.
            var deploy = await BrowseAsync( "deploy" );
            var offer = deploy[^1];
            Equal( "herdr:new-tab:w1", offer.Id );
            Equal( "Create tab \"deploy\"", offer.Title );
            Equal( "New tab in CommandDeck", offer.Subtitle );
            Equal( "herdr-create-tab", offer.Actions.Single( ).Kind );
            Equal( "deploy", offer.Actions.Single( ).Inputs.Single( ).DefaultValue );

            // A partial name keeps the matching tab first.
            var partial = await BrowseAsync( "rel" );
            Equal( "herdr:tab:w1:t2", partial[0].Id );
            Equal( "herdr:new-tab:w1", partial[^1].Id );

            // An exact tab name, plain search, a filter, or an exclusion offers nothing.
            True( !(await BrowseAsync( "Tests" )).Any( static row => row.Id.StartsWith( "herdr:new-tab:", StringComparison.Ordinal ) ) );
            True( !(await BrowseAsync( "deploy", workspaceId: null )).Any( static row => row.Id.StartsWith( "herdr:new-tab:", StringComparison.Ordinal ) ) );
            True( !(await BrowseAsync( "hattention: deploy" )).Any( static row => row.Id.StartsWith( "herdr:new-tab:", StringComparison.Ordinal ) ) );
            True( !(await BrowseAsync( "deploy -release" )).Any( static row => row.Id.StartsWith( "herdr:new-tab:", StringComparison.Ordinal ) ) );

            // Creating binds the space the offer was made for.
            await BrowseAsync( "deploy" );
            var outcome = await runtime.InvokeAsync( "herdr:new-tab:w1", "create-tab", false, default, new Dictionary<string, string> { ["Name"] = "deploy" } );
            True( outcome.Succeeded, outcome.Message );
            Equal( "--session|default|tab|create|--workspace|w1|--label|deploy|--no-focus",
                string.Join( '|', fake.Calls.Single( static call => call.Args[3] == "create" ).Args ) );

            // A forged target for the offer row never reaches Herdr.
            var forged = new CommandAction
            {
                Id = "create-tab",
                Title = "Create Tab",
                Kind = ActionKinds.HerdrCreateTab,
                Arguments = new( StringComparer.Ordinal ) { [ActionArgumentNames.TargetId] = "w2", ["input:Name"] = "deploy" }
            };

            True( !(await new LinuxActionExecutor( herdr: client ).ExecuteAsync( offer, forged, "", default )).Succeeded );
            Equal( 1, fake.Calls.Count( static call => call.Args[3] == "create" ) );
        }
        finally
        {
            Directory.Delete( directory, recursive: true );
        }
    }
}
