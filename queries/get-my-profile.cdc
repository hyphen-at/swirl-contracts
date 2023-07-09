import SwirlNametag from "../contracts/SwirlNametag.cdc"

/// Retrieve the SwirlNametag.Profile from the given address.
/// If nametag doesn't exist on the address, it returns nil.
pub fun main(address: Address): SwirlNametag.Profile? {
    let account = getAccount(address)

    if let collection = account.getCapability(SwirlNametag.CollectionPublicPath).borrow<&{SwirlNametag.SwirlNametagCollectionPublic}>() {
        let tokenIDs = collection.getIDs()
        if tokenIDs.length == 0 {
            return nil
        }
        let nft = collection.borrowSwirlNametag(id: tokenIDs[0])!
        let metadata = nft.resolveView(Type<SwirlNametag.Profile>())!

        return metadata as? SwirlNametag.Profile ?? panic("invalid resolveView implementation on SwirlNametag")
    }
    // nametag NFT not found
    return nil
}
