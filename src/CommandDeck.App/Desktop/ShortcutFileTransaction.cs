namespace CommandDeck;

// Atomic per-file replacements plus rollback across the JSON/module pair. The
// reload is part of the transaction, and rollback reloads the previous files.
public static class ShortcutFileTransaction
{
    public static async ValueTask ApplyAsync( IReadOnlyDictionary<string, string?> updates, Func<CancellationToken, ValueTask> reload,
        CancellationToken cancellationToken )
    {
        var previous = updates.Keys.ToDictionary( static path => path, static path => File.Exists( path ) ? File.ReadAllText( path ) : null, StringComparer.Ordinal );
        List<string> applied = [];
        try
        {
            foreach ( var (path, content) in updates )
            {
                if ( previous[path] is { } old )
                {
                    Write( path + ".bak", old );
                }

                Write( path, content );
                applied.Add( path );
            }
            await reload( cancellationToken ).ConfigureAwait( false );
        }
        catch
        {
            foreach ( var path in applied.AsEnumerable( ).Reverse( ) )
            {
                Write( path, previous[path] );
            }

            try
            { await reload( CancellationToken.None ).ConfigureAwait( false ); }
            catch ( Exception exception ) when ( exception is IOException or InvalidOperationException ) { /* originals remain on disk */ }
            throw;
        }
    }

    private static void Write( string path, string? content )
    {
        if ( content is null )
        { File.Delete( path ); return; }
        if ( File.Exists( path ) )
        {
            path = File.ResolveLinkTarget( path, returnFinalTarget: true )?.FullName ?? path;
        }

        Directory.CreateDirectory( Path.GetDirectoryName( path )! );
        var temporary = path + "." + Guid.NewGuid( ).ToString( "N" ) + ".tmp";
        try
        {
            File.WriteAllText( temporary, content );
            if ( File.Exists( path ) && !OperatingSystem.IsWindows( ) )
            {
                File.SetUnixFileMode( temporary, File.GetUnixFileMode( path ) );
            }

            File.Move( temporary, path, overwrite: true );
        }
        finally { File.Delete( temporary ); }
    }
}
