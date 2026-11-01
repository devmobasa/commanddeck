namespace CommandDeck;

public sealed partial class HerdrProvider
{
    private static CommandAction SpaceAction( string id, string title, string kind, string workspaceId ) => new( )
    {
        Id = id,
        Title = title,
        Kind = kind,
        Arguments = new( StringComparer.Ordinal ) { [ActionArgumentNames.TargetId] = workspaceId },
        Inputs = CreateWorkflowInputs( kind )
    };

    private static void AddTabPreview( List<DetailField> details, string workspaceId, IReadOnlyList<HerdrTab> tabs )
    {
        const int previewLimit = 8;
        var children = OrderWorkspaceTabs( workspaceId, tabs );
        foreach ( var tab in children.Take( previewLimit ) )
        {
            var label = tab.Label.Length > 0 ? tab.Label : $"Tab {tab.Number}";
            var status = tab.AgentStatus.Length > 0 ? $" · {tab.AgentStatus}" : string.Empty;
            details.Add( new DetailField( label, Plural( tab.PaneCount, "pane" ) + status ) );
        }

        if ( children.Length > previewLimit )
        {
            details.Add( new DetailField( "More tabs", $"{children.Length - previewLimit} more — choose Browse tabs" ) );
        }
    }

    private const string CreateTabActionId = "create-tab";
    private const double CreateTabScore = 0.01;

    // Filter or create: in a browsed space, text that names no tab offers to
    // create one with that name, after the matching tabs. The name dialog opens
    // with the text filled in. An exact tab name, a filter, a field or excluded
    // clause, or a name Herdr would refuse offers nothing.
    private static SearchResult? CreateTabOffer( HerdrInventory inventory, ParsedQuery query, string? workspaceId )
    {
        var name = query.Text.Trim( );
        if ( workspaceId is null || IsUnusableTabName( name ) || query.IncludedFilters.Count > 0 || query.ExcludedFilters.Count > 0 ||
             query.Expression.Clauses.Any( static clause => clause.Field is not null || clause.Excluded ) )
        {
            return null;
        }

        var workspace = inventory.Workspaces.FirstOrDefault( workspace => workspace.Id == workspaceId );
        if ( workspace is null ||
             inventory.Tabs.Any( tab => tab.WorkspaceId == workspaceId && string.Equals( tab.Label, name, StringComparison.OrdinalIgnoreCase ) ) )
        {
            return null;
        }

        var space = workspace.Label.Length > 0 ? workspace.Label : $"Space {workspace.Number}";

        return new SearchResult
        {
            Id = HerdrSearch.NewTabResultPrefix + workspace.Id,
            Kind = ResultKinds.Workspace,
            Title = $"Create tab \"{name}\"",
            Subtitle = $"New tab in {space}",
            Icon = Icon,
            ProviderId = ProviderIds.Herdr,
            SourceId = SourceIds.Herdr,
            Score = CreateTabScore,
            Details = [new DetailField( "Space", space ), new DetailField( "Name", name )],
            Actions =
            [
                new CommandAction
                {
                    Id = CreateTabActionId,
                    Title = "Create Tab",
                    Kind = ActionKinds.HerdrCreateTab,
                    Arguments = new( StringComparer.Ordinal ) { [ActionArgumentNames.TargetId] = workspace.Id },
                    Inputs = [new ActionInput { Name = NameInput, DefaultValue = name }]
                }
            ],
            Metadata = new Dictionary<string, string>( StringComparer.Ordinal )
            {
                [TargetKindMetadata] = HerdrTargetKinds.Workspace,
                [TargetIdMetadata] = workspace.Id,
                [WorkspaceIdMetadata] = workspace.Id,
                [WorkspaceLabelMetadata] = workspace.Label
            }
        };
    }

    private static bool IsUnusableTabName( string name )
    {
        return name.Length == 0 || name.Length > HerdrClient.MaximumLabelCharacters || name.Any( char.IsControl );
    }

    private static List<ActionInput> CreateWorkflowInputs( string kind )
    {
        if ( kind == ActionKinds.HerdrCreateTab )
        {
            return [new ActionInput { Name = NameInput, DefaultValue = "New tab" }];
        }

        return [];
    }

    private static HerdrTab[] OrderWorkspaceTabs( string workspaceId, IReadOnlyList<HerdrTab> tabs )
    {
        return tabs
            .Where( tab => tab.WorkspaceId == workspaceId )
            .OrderBy( static tab => tab.Number )
            .ThenBy( static tab => tab.Id, StringComparer.Ordinal )
            .ToArray( );
    }
}
