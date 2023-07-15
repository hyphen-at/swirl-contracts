import SwirlNametag from "../contracts/SwirlNametag.cdc"
import SwirlMoment from "../contracts/SwirlMoment.cdc"

/// Retrieve the SwirlNametag.Profile from the given address.
/// If nametag doesn't exist on the address, it returns nil.
pub fun main(address: Address): [SwirlNametag.Profile] {
    let account = getAccount(address)
    let profiles: [SwirlNametag.Profile] = []

    if let collection = account.getCapability(SwirlMoment.CollectionPublicPath).borrow<&{SwirlMoment.SwirlMomentCollectionPublic}>() {
        for tokenID in collection.getIDs() {
            let nft = collection.borrowSwirlMoment(id: tokenID)!
            let metadata = nft.resolveView(Type<SwirlNametag.Profile>())!

            let profile = metadata as? SwirlNametag.Profile ?? panic("invalid resolveView implementation on SwirlNametag")
            profiles.append(profile)
        }
    }
    return profiles
}
