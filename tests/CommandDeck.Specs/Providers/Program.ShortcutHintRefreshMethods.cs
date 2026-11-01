namespace CommandDeck.Specs;

public static partial class Program
{
    private static async Task ShortcutHintsUpdateBeforeAnOlderReadCompletesAsync( )
    {
        TaskCompletionSource<string?> pending = new( TaskCreationOptions.RunContinuationsAsynchronously );
        KeybindingHints hints = new( _ => new ValueTask<string?>( pending.Task ), static ( ) => true );
        SearchResult result = new( ) { Id = "fixture", Kind = ResultKinds.CustomCommand, SourceId = SourceIds.DesktopControls, Title = "Menu" };
        _ = hints.Decorate( [result] );
        hints.ApplyInventory( [new( ) { Description = "Menu", Chord = "Super+J" }] );
        Equal( "Super+J", hints.Decorate( [result] )[0].Metadata[ResultMetadataKeys.Keybinding] );
        pending.SetResult( ShortcutFixtureInventoryJson );
        await hints.Refresh;
        Equal( "Super+J", hints.Decorate( [result] )[0].Metadata[ResultMetadataKeys.Keybinding] );
        hints.ApplyInventory( [new( ) { Description = "Menu", Chord = "" }] );
        True( !hints.Decorate( [result] )[0].Metadata.ContainsKey( ResultMetadataKeys.Keybinding ) );
    }
}
