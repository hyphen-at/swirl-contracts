import SwirlNametag from "../contracts/SwirlNametag.cdc"

/// Updates existing nametag.
transaction(
    nickname: String,
    profileImage: String,
    keywords: [String],
    color: String,
    twitterHandle: String?,
    telegramHandle: String?,
    discordHandle: String?,
    threadHandle: String?
) {
    let collection: &SwirlNametag.Collection
    let newProfile: SwirlNametag.Profile

    prepare(signer: AuthAccount) {
        self.collection = signer.borrow<&SwirlNametag.Collection>(from: SwirlNametag.CollectionStoragePath)
            ?? panic("Could not borrow a reference to the SwirlNametag collection")

        if self.collection.getIDs().length == 0 {
            panic("No nametags exist in the collection")
        }

        let socialHandles: [SwirlNametag.SocialHandle] = []
        if twitterHandle != nil {
            socialHandles.append(SwirlNametag.SocialHandle(
                type: "twitter",
                value: twitterHandle!
            ))
        }
        if telegramHandle != nil {
            socialHandles.append(SwirlNametag.SocialHandle(
                type: "telegram",
                value: telegramHandle!
            ))
        }
        if discordHandle != nil {
            socialHandles.append(SwirlNametag.SocialHandle(
                type: "twitter",
                value: discordHandle!
            ))
        }
        if threadHandle != nil {
            socialHandles.append(SwirlNametag.SocialHandle(
                type: "thread",
                value: threadHandle!
            ))
        }

        self.newProfile = SwirlNametag.Profile(
            nickname: nickname,
            profileImage: profileImage,
            keywords: keywords,
            color: color,
            socialHandles: socialHandles
        )
    }

    execute {
        self.collection.updateSwirlNametag(profile: self.newProfile)
    }
}
