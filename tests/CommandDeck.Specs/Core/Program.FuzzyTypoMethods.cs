namespace CommandDeck.Specs;

public static partial class Program
{
    private static void FuzzyTypoMatchesWordStillBeingTyped( )
    {
        foreach ( var query in ( string[] ) ["frie", "fierf", "fierfo"] )
        {
            True( FuzzyMatcher.Score( query, "Firefox" ) >= 0.55 );
            Equal( new MatchedRange( 0, query.Length ), FuzzyMatcher
                .FindRanges( query, "Firefox" )
                .Single( ) );
        }

        // A typo that stops inside a word ranks just below one that completes it.
        True( FuzzyMatcher.Score( "fierf", "Firefox" ) < FuzzyMatcher.Score( "fierfox", "Firefox" ) );
        Equal( 0d, FuzzyMatcher.Score( "fierf", "Chromium" ) );
    }

    private static void FuzzyTypoRunsAcrossWords( )
    {
        True( FuzzyMatcher.Score( "googel chrome", "Google Chrome" ) >= 0.55 );
        Equal( new MatchedRange( 0, "Google Chrome".Length ), FuzzyMatcher
            .FindRanges( "googel chrome", "Google Chrome" )
            .Single( ) );

        // The highlight ends at the word end rather than inside "Studio".
        Equal( new MatchedRange( 0, "Visual Studio".Length ), FuzzyMatcher
            .FindRanges( "visual studo", "Visual Studio Code" )
            .Single( ) );

        Equal( new MatchedRange( "Google ".Length, "Chrome".Length ), FuzzyMatcher
            .FindRanges( "chrmoe", "Google Chrome" )
            .Single( ) );
    }

    private static void FuzzyTypoKeepsDigitsAndPunctuationAsTyped( )
    {
        Equal( 0d, FuzzyMatcher.Score( "python3", "python2" ) );
        Equal( 0d, FuzzyMatcher.Score( "gpt4", "gpt5" ) );
        Equal( 0d, FuzzyMatcher.Score( "omarchy 4.0", "Omarchy 4.5" ) );
        True( FuzzyMatcher.Score( "pyhton3", "python3" ) >= 0.55 );
    }

    private static void FuzzyTypoDropsExtraQueryLetterOnlyAtWordEnd( )
    {
        Equal( 0d, FuzzyMatcher.Score( "fiire", "Firefox" ) );
        True( FuzzyMatcher.Score( "fiire", "Fire Station" ) >= 0.55 );
        Equal( new MatchedRange( 0, "Fire".Length ), FuzzyMatcher
            .FindRanges( "fiire", "Fire Station" )
            .Single( ) );
    }

    private static void FuzzyTypoNeedsFourCharactersAndALetterOrDigitFirst( )
    {
        Equal( 0d, FuzzyMatcher.Score( "fri", "Firefox" ) );
        Equal( 0d, FuzzyMatcher.Score( "-fierfox", "Firefox" ) );
    }

    private static void FuzzyTypoStaysBoundedOnLongCandidates( )
    {
        // Every other character starts a word, so nearly every position starts
        // an alignment, and three transpositions exceed the two-edit budget.
        var candidate = string.Concat( Enumerable
            .Range( 0, ProtocolLimits.MaximumQueryCharacters )
            .Select( static index => ( char ) ((index % 2 == 0 ? 'a' : 'A') + (index % 26)) ) );

        var letters = Enumerable
            .Range( 0, 48 )
            .Select( static index => ( char ) ('a' + (index % 26)) )
            .ToArray( );

        foreach ( var at in ( int[] ) [5, 20, 35] )
        {
            (letters[at], letters[at + 1]) = (letters[at + 1], letters[at]);
        }

        var query = new string( letters );
        var stopwatch = System.Diagnostics.Stopwatch.StartNew( );
        for ( var iteration = 0; iteration < 10; iteration++ )
        {
            True( FuzzyMatcher.Score( query, candidate ) < 0.53 );
        }

        stopwatch.Stop( );
        True( stopwatch.Elapsed < TimeSpan.FromMilliseconds( 250 ) );
    }
}
