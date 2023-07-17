import NonFungibleToken from "../contracts/utility/NonFungibleToken.cdc"
import MetadataViews from "../contracts/utility/MetadataViews.cdc"
import SwirlMoment from "../contracts/SwirlMoment.cdc"
import SwirlNametag from "../contracts/SwirlNametag.cdc"

/// Sets up collections of SwirlMoment, SwirlNametag for an account so it can receive these NFTs,
/// and mints a SwirlNametag which acts as the account's profile.
///
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
    let collectionRef: &{NonFungibleToken.CollectionPublic}
    let profile: SwirlNametag.Profile

    prepare(signer: AuthAccount) {
        if signer.borrow<&SwirlMoment.Collection>(from: SwirlMoment.CollectionStoragePath) == nil {
            // set up SwirlMoment.Collection to the account.
            signer.save(<-SwirlMoment.createEmptyCollection(), to: SwirlMoment.CollectionStoragePath)
            signer.link<&{NonFungibleToken.CollectionPublic, SwirlMoment.SwirlMomentCollectionPublic, MetadataViews.ResolverCollection}>(
                SwirlMoment.CollectionPublicPath,
                target: SwirlMoment.CollectionStoragePath
            )
        }

        if signer.borrow<&SwirlNametag.Collection>(from: SwirlNametag.CollectionStoragePath) == nil {
            // set up SwirlNametag.Collection to the account.
            signer.save(<-SwirlNametag.createEmptyCollection(), to: SwirlNametag.CollectionStoragePath)
            signer.link<&{NonFungibleToken.CollectionPublic, SwirlNametag.SwirlNametagCollectionPublic, MetadataViews.ResolverCollection}>(
                SwirlNametag.CollectionPublicPath,
                target: SwirlNametag.CollectionStoragePath
            )
        }

        self.collectionRef = signer.borrow<&{NonFungibleToken.CollectionPublic}>(from: SwirlNametag.CollectionStoragePath)
            ?? panic("Could not borrow a reference to the SwirlNametag collection")

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
                type: "discord",
                value: discordHandle!
            ))
        }
        if threadHandle != nil {
            socialHandles.append(SwirlNametag.SocialHandle(
                type: "thread",
                value: threadHandle!
            ))
        }

        self.profile = SwirlNametag.Profile(
            nickname: nickname,
            profileImage: profileImage,
            keywords: keywords,
            color: color,
            socialHandles: socialHandles
        )
    }

    execute {
        SwirlNametag.mintNFT(recipient: self.collectionRef, profile: self.profile)
    }
}
