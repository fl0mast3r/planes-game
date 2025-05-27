local ProfileConfig = {
    Money = 0,
    Wins = 0,
    Unlocked = {"Basic", "Wood"} :: {string}?
}

export type Type = typeof(ProfileConfig)
return ProfileConfig