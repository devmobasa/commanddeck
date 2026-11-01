namespace CommandDeck.Specs;

public static partial class Program
{
    // Hyprland clients as `hyprctl -j clients` reports them; addresses and titles are invented.
    private const string ApplicationClientsJson = """
                                                  [
                                                    {"address":"0x1","mapped":true,"hidden":false,"class":"firefox","initialClass":"firefox","title":"Docs","focusHistoryID":3},
                                                    {"address":"0x2","mapped":true,"hidden":false,"class":"firefox","initialClass":"firefox","title":"Mail","focusHistoryID":1},
                                                    {"address":"0x3","mapped":true,"hidden":true,"class":"firefox","initialClass":"firefox","title":"Hidden","focusHistoryID":0},
                                                    {"address":"0x4","mapped":false,"hidden":false,"class":"firefox","initialClass":"firefox","title":"Unmapped","focusHistoryID":0},
                                                    {"address":"0x5","mapped":true,"hidden":false,"class":"chrome-discord.com__channels_@me-Profile_1","initialClass":"chrome-discord.com__channels_@me-Profile_1","title":"Discord","focusHistoryID":2},
                                                    {"address":"0x6","mapped":true,"hidden":false,"class":"Code","initialClass":"Code","title":"Editor","focusHistoryID":4}
                                                  ]
                                                  """;

    private static CommandAction ApplicationLaunch( string desktopId, string? wmClass = null, string name = "Firefox",
        Dictionary<string, string>? extra = null )
    {
        Dictionary<string, string> arguments = new( StringComparer.Ordinal )
        {
            [ResultMetadataKeys.Application.DesktopId] = desktopId,
            [ResultMetadataKeys.Application.Name] = name
        };

        if ( wmClass is not null )
        {
            arguments[ResultMetadataKeys.Application.StartupWmClass] = wmClass;
        }

        foreach ( var (key, value) in extra ?? [] )
        {
            arguments[key] = value;
        }

        return new CommandAction { Id = "launch", Title = "Launch", Kind = ActionKinds.LaunchDesktop, Arguments = arguments };
    }

    private static void ApplicationWindowsMatchByClassAcrossWebAppProfiles( )
    {
        HashSet<string> Keys( CommandAction action ) => ApplicationWindowFocus.WindowKeys( action );

        // The most recently focused visible window wins; hidden and unmapped ones never do.
        Equal( "0x2", ApplicationWindowFocus.FindWindow( ApplicationClientsJson, Keys( ApplicationLaunch( "firefox.desktop" ) ) ) );
        Equal( "0x6", ApplicationWindowFocus.FindWindow( ApplicationClientsJson, Keys( ApplicationLaunch( "code.desktop" ) ) ) );

        // A Chromium web app in another profile is the same app.
        var discord = ApplicationLaunch( "chrome-discord.com__channels_@me-Default.desktop", "chrome-discord.com__channels_@me-Default", "Discord" );
        Equal( "chrome-discord.com__channels_@me", Keys( discord ).Single( ) );
        Equal( "0x5", ApplicationWindowFocus.FindWindow( ApplicationClientsJson, Keys( discord ) ) );
        Equal( "brave-browser", ApplicationWindowFocus.Normalize( "brave-browser" ) );

        True( ApplicationWindowFocus.FindWindow( ApplicationClientsJson, Keys( ApplicationLaunch( "obsidian.desktop" ) ) ) is null );
        True( ApplicationWindowFocus.FindWindow( "not json", Keys( ApplicationLaunch( "firefox.desktop" ) ) ) is null );
    }

    private static async Task ApplicationLaunchFocusesAnOpenWindowAsync( )
    {
        List<string> calls = [];
        var dispatchReply = "ok";
        var clientsReply = ApplicationClientsJson;

        ValueTask<ProcessResult> HyprctlAsync( string file, IReadOnlyList<string> arguments, TimeSpan timeout, CancellationToken token )
        {
            Equal( "hyprctl", file );
            calls.Add( string.Join( ' ', arguments ) );
            var output = arguments[0] == "dispatch" ? dispatchReply : clientsReply;

            return ValueTask.FromResult( new ProcessResult { ExitCode = 0, StandardOutput = output, StandardError = "" } );
        }

        var inHyprland = true;
        ApplicationWindowFocus focus = new( HyprctlAsync, ( ) => inHyprland );

        var switched = await focus.TryFocusAsync( ApplicationLaunch( "firefox.desktop" ), default );
        True( switched is { Succeeded: true } );
        Equal( "Switched to Firefox", switched!.Message );
        Equal( "-j clients|dispatch hl.dsp.focus({ window = \"address:0x2\" })", string.Join( '|', calls ) );

        // Open New Window, a terminal entry, a launch that opens files, and no Hyprland always launch.
        foreach ( var launch in new[]
                 {
                     ApplicationLaunch( "firefox.desktop", extra: new( ) { [ActionArgumentNames.NewInstance] = "true" } ),
                     ApplicationLaunch( "firefox.desktop", extra: new( ) { [ResultMetadataKeys.Application.Terminal] = "true" } ),
                     ApplicationLaunch( "firefox.desktop", extra: new( ) { [ResultMetadataKeys.Application.LaunchArguments] = "notes.md" } )
                 } )
        {
            calls.Clear( );
            True( await focus.TryFocusAsync( launch, default ) is null );
            Equal( 0, calls.Count );
        }

        inHyprland = false;
        calls.Clear( );
        True( await focus.TryFocusAsync( ApplicationLaunch( "firefox.desktop" ), default ) is null );
        Equal( 0, calls.Count );
        inHyprland = true;

        // No open window, or a focus Hyprland does not acknowledge, launches instead.
        True( await focus.TryFocusAsync( ApplicationLaunch( "obsidian.desktop", name: "Obsidian" ), default ) is null );
        dispatchReply = "warning: no such window";
        True( await focus.TryFocusAsync( ApplicationLaunch( "firefox.desktop" ), default ) is null );
    }
}
