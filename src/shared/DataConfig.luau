local ProfileConfig = {
    Money = 0,
    Wins = 10,
    Unlocked = {"Basic", "Wood"} :: {string}?,
}

export type Type = typeof(ProfileConfig)
return ProfileConfig