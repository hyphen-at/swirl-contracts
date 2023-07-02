import NonFungibleToken from "./utility/NonFungibleToken.cdc"
import MetadataViews from "./utility/MetadataViews.cdc"

pub contract SwirlMomentSBT: NonFungibleToken {
    pub var totalSupply: UInt64

    pub event ContractInitialized()
    pub event Withdraw(id: UInt64, from: Address?)
    pub event Deposit(id: UInt64, to: Address?)

    pub let CollectionStoragePath: StoragePath
    pub let CollectionPublicPath: PublicPath
    pub let MinterStoragePath: StoragePath
    pub let ProviderPrivatePath: PrivatePath

    pub struct Person {
        pub let name: String
        pub let address: Address
        pub let profileJSON: String
        pub let metLocationLat: Fix64
        pub let metLocationLng: Fix64

        init(name: String, address: Address, profileJSON: String, metLocationLat: Fix64, metLocationLng: Fix64) {
            self.name = name
            self.address = address
            self.profileJSON = profileJSON
            self.metLocationLat = metLocationLat
            self.metLocationLng = metLocationLng
        }
    }

    pub struct SwirlMomentSBTMintData {
        pub let id: UInt64
        pub let description: String
        pub let thumbnail: String
        pub let persons: [Person]

        init(id: UInt64, description: String, thumbnail: String, persons: [Person]) {
            self.id = id
            self.description = description
            self.thumbnail = thumbnail
            self.persons = persons
        }
    }

    pub resource NFT: NonFungibleToken.INFT, MetadataViews.Resolver {
        pub let id: UInt64
        pub let description: String
        pub let thumbnail: String
        pub let persons: [Person]

        init(id: UInt64, description: String, thumbnail: String, persons: [Person]) {
            self.id = id
            self.description = description
            self.thumbnail = thumbnail
            self.persons = persons
        }

        pub fun getViews(): [Type] {
            let views: [Type] = [
                    Type<SwirlMomentSBTMintData>(),
                    Type<MetadataViews.Display>(),
                    Type<MetadataViews.Serial>(),
                    Type<MetadataViews.ExternalURL>(),
                    Type<MetadataViews.NFTCollectionData>(),
                    Type<MetadataViews.NFTCollectionDisplay>(),
                    Type<MetadataViews.Traits>()
                ]
            return views
        }

        pub fun name(): String {
            return "Swirl: "
                .concat(self.persons[0].name)
                .concat(" <> ")
                .concat(self.persons[1].name)
        }

        /// Function that resolve the given GameMetadataView
        ///
        /// @param view: The Type of GameMetadataView to resolve
        ///
        /// @return The resolved GameMetadataView for this NFT with this NFT's
        /// metadata or nil if none exists
        ///
        pub fun resolveView(_ view: Type): AnyStruct? {
            switch view {
                case Type<SwirlMomentSBTMintData>():
                    return SwirlMomentSBTMintData(
                        id: self.id,
                        description: self.description,
                        thumbnail: self.thumbnail,
                        persons: self.persons
                    )

                case Type<MetadataViews.Display>():
                    return MetadataViews.Display(
                        name: self.name(),
                        description: self.description,
                        thumbnail: MetadataViews.HTTPFile(url: self.thumbnail),
                    )
                case Type<MetadataViews.Serial>():
                    return MetadataViews.Serial(
                        self.id
                    )
                case Type<MetadataViews.ExternalURL>():
                    return MetadataViews.ExternalURL("https://api.hyphen.at/art/v1/".concat(self.id.toString()))
                case Type<MetadataViews.NFTCollectionData>():
                    return MetadataViews.NFTCollectionData(
                        storagePath: SwirlMomentSBT.CollectionStoragePath,
                        publicPath: SwirlMomentSBT.CollectionPublicPath,
                        providerPath: SwirlMomentSBT.ProviderPrivatePath,
                        publicCollection: Type<&SwirlMomentSBT.Collection{SwirlMomentSBT.SwirlMomentSBTCollectionPublic}>(),
                        publicLinkedType: Type<&SwirlMomentSBT.Collection{SwirlMomentSBT.SwirlMomentSBTCollectionPublic, NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection}>(),
                        providerLinkedType: Type<&SwirlMomentSBT.Collection{SwirlMomentSBT.SwirlMomentSBTCollectionPublic, NonFungibleToken.CollectionPublic, NonFungibleToken.Provider, MetadataViews.ResolverCollection}>(),
                        createEmptyCollectionFunction: (fun (): @NonFungibleToken.Collection {
                            return <-SwirlMomentSBT.createEmptyCollection()
                        })
                    )
                case Type<MetadataViews.NFTCollectionDisplay>():
                    let media = MetadataViews.Media(
                        file: MetadataViews.HTTPFile(url: self.thumbnail),
                        mediaType: "image/png"
                    )

                    let bannerMedia = MetadataViews.Media(
                        file: MetadataViews.HTTPFile(url: self.thumbnail),
                        mediaType: "image/png"
                    )
                    return MetadataViews.NFTCollectionDisplay(
                        name: "Swirl Moment",
                        description: "The moment you met someone at IRL, saved on your wallet as SBT.",
                        externalURL: MetadataViews.ExternalURL("https://hyphen.at/"),
                        squareImage: media,
                        bannerImage: bannerMedia,
                        socials: {}
                    )
                case Type<MetadataViews.Traits>():
                    let traitsView = MetadataViews.dictToTraits(dict: {}, excludedNames: [])

                    return traitsView
                default:
                    return nil
            }
        }
    }

    pub resource interface SwirlMomentSBTCollectionPublic {
        pub fun deposit(token: @NonFungibleToken.NFT)
        pub fun getIDs(): [UInt64]
        pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT
        pub fun borrowSwirlMomentSBT(id: UInt64): &SwirlMomentSBT.NFT? {
            post {
                (result == nil) || (result?.id == id):
                    "Cannot borrow SwirlMomentSBT reference: the ID of the returned reference is incorrect"
            }
        }
    }

    pub resource Collection: SwirlMomentSBTCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic, MetadataViews.ResolverCollection {
        // dictionary of NFT conforming tokens
        // NFT is a resource type with an `UInt64` ID field
        pub var ownedNFTs: @{UInt64: NonFungibleToken.NFT}

        init () {
            self.ownedNFTs <- {}
        }

        // withdraw removes an NFT from the collection and moves it to the caller
        pub fun withdraw(withdrawID: UInt64): @NonFungibleToken.NFT {
            let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("missing NFT")

            emit Withdraw(id: token.id, from: self.owner?.address)

            return <-token
        }

        // deposit takes an NFT and adds it to the collections dictionary
        // and adds the ID to the id array
        pub fun deposit(token: @NonFungibleToken.NFT) {
            let token <- token as! @SwirlMomentSBT.NFT

            let id: UInt64 = token.id

            // add the new token to the dictionary which removes the old one
            let oldToken <- self.ownedNFTs[id] <- token

            emit Deposit(id: id, to: self.owner?.address)

            destroy oldToken
        }

        // getIDs returns an array of the IDs that are in the collection
        pub fun getIDs(): [UInt64] {
            return self.ownedNFTs.keys
        }

        // borrowNFT gets a reference to an NFT in the collection
        // so that the caller can read its metadata and call its methods
        pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT {
            return (&self.ownedNFTs[id] as &NonFungibleToken.NFT?)!
        }

        pub fun borrowSwirlMomentSBT(id: UInt64): &SwirlMomentSBT.NFT? {
            if self.ownedNFTs[id] != nil {
                // Create an authorized reference to allow downcasting
                let ref = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
                return ref as! &SwirlMomentSBT.NFT
            }

            return nil
        }

        pub fun borrowViewResolver(id: UInt64): &AnyResource{MetadataViews.Resolver} {
            let nft = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
            let SwirlMomentSBTNFT = nft as! &SwirlMomentSBT.NFT
            return SwirlMomentSBTNFT as &AnyResource{MetadataViews.Resolver}
        }

        destroy() {
            destroy self.ownedNFTs
        }
    }

    pub resource Minter {
        pub fun mintNFT(
            recipient: &{NonFungibleToken.CollectionPublic},
            id: UInt64,
            description: String,
            thumbnail: String,
            persons: [Person]
        ) {
            // create a new NFT
            var newNFT <- create NFT(
                id: id,
                description: description,
                thumbnail: thumbnail,
                persons: persons,
            )
            recipient.deposit(token: <-newNFT)
            SwirlMomentSBT.totalSupply = SwirlMomentSBT.totalSupply + UInt64(1)
        }
    }

    // public function that anyone can call to create a new empty collection
    pub fun createEmptyCollection(): @NonFungibleToken.Collection {
        return <- create Collection()
    }

    pub fun createMinter(): @Minter {
        return <- create Minter()
    }

    init() {
        self.totalSupply = 0

        self.CollectionStoragePath = /storage/SwirlMomentSBTCollection
        self.CollectionPublicPath = /public/SwirlMomentSBTCollection
        self.MinterStoragePath = /storage/SwirlMomentSBTMinter
        self.ProviderPrivatePath = /private/SwirlNFTCollectionProvider

        // Create a Collection resource and save it to storage
        let collection <- create Collection()
        self.account.save(<-collection, to: self.CollectionStoragePath)

        self.account.link<&SwirlMomentSBT.Collection{NonFungibleToken.CollectionPublic, SwirlMomentSBT.SwirlMomentSBTCollectionPublic, MetadataViews.ResolverCollection}>(
            self.CollectionPublicPath,
            target: self.CollectionStoragePath
        )

        let minter <- create Minter()
        self.account.save(<-minter, to: self.MinterStoragePath)

        emit ContractInitialized()
    }
}
