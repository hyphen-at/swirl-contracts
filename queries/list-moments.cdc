import SwirlNametag from "../contracts/SwirlNametag.cdc"
import SwirlMoment from "../contracts/SwirlMoment.cdc"

pub struct MomentInfo {
    pub let profile: SwirlNametag.Profile
    pub let location: SwirlMoment.Coordinate
    pub let mintedAt: UFix64

    init(profile: SwirlNametag.Profile, location: SwirlMoment.Coordinate, mintedAt: UFix64) {
        self.profile = profile
        self.location = location
        self.mintedAt = mintedAt
    }
}

/// Retrieve the SwirlNametag.Profile from the given address.
/// If nametag doesn't exist on the address, it returns nil.
pub fun main(address: Address): [MomentInfo] {
    let account = getAccount(address)
    let moments: [MomentInfo] = []

    if let collection = account.getCapability(SwirlMoment.CollectionPublicPath).borrow<&{SwirlMoment.SwirlMomentCollectionPublic}>() {
        for tokenID in collection.getIDs() {
            let nft = collection.borrowSwirlMoment(id: tokenID)!
            moments.append(MomentInfo(profile: nft.profile(), location: nft.location, mintedAt: nft.mintedAt))
        }
    }
    return moments
}
