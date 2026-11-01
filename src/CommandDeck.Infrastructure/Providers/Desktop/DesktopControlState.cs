using System.Text.Json;

namespace CommandDeck;

// A control that flips one setting. Its row is named for what it will do next,
// from a probe of the current state, and keeps its toggle title when the probe
// gives no answer. On means muted for audio and unblocked for a radio.
internal sealed record DesktopControlState(
    IReadOnlyList<string> ProbeArgv,
    Func<string, bool?> ReadIsOn,
    string TitleWhenOn,
    string TitleWhenOff,
    string StateWhenOn,
    string StateWhenOff )
{
    public string Title( bool isOn ) => isOn ? TitleWhenOn : TitleWhenOff;

    public string Describe( bool isOn ) => isOn ? StateWhenOn : StateWhenOff;

    public string ProbeKey => string.Join( '\u001f', ProbeArgv );
}

internal static class DesktopControlProbes
{
    private const string VolumePrefix = "Volume:";
    private const string MutedMarker = "[MUTED]";
    private const string Unblocked = "unblocked";

    // wpctl get-volume prints "Volume: 0.40", with " [MUTED]" when muted.
    public static bool? ReadMuted( string output )
    {
        var line = output.Trim( );
        if ( !line.StartsWith( VolumePrefix, StringComparison.Ordinal ) )
        {
            return null;
        }

        return line.Contains( MutedMarker, StringComparison.Ordinal );
    }

    // rfkill -J lists each radio's soft and hard block. The radio counts as on
    // when any device of the type is fully unblocked; no device means unknown.
    public static Func<string, bool?> ReadRadioOn( string type ) => output =>
    {
        try
        {
            using var document = JsonDocument.Parse( output );
            if ( !document.RootElement.TryGetProperty( "rfkilldevices", out var devices ) || devices.ValueKind != JsonValueKind.Array )
            {
                return null;
            }

            bool? on = null;
            foreach ( var device in devices.EnumerateArray( ) )
            {
                if ( Text( device, "type" ) == type )
                {
                    on = on == true || (Text( device, "soft" ) == Unblocked && Text( device, "hard" ) == Unblocked);
                }
            }

            return on;
        }
        catch ( JsonException )
        {
            return null;
        }
    };

    private static string? Text( JsonElement element, string property )
    {
        return element.ValueKind == JsonValueKind.Object && element.TryGetProperty( property, out var value ) && value.ValueKind == JsonValueKind.String
            ? value.GetString( )
            : null;
    }
}
