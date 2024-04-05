import "MetadataViews"
import "NFTCatalog"
import "NFTRetrieval"
import "ViewResolver"

access(all) struct NFT {
    access(all) let id: UInt64
    access(all) let name: String
    access(all) let description: String
    access(all) let thumbnail: String
    access(all) let externalURL: String
    access(all) let storagePath: StoragePath
    access(all) let publicPath: PublicPath
    access(all) let privatePath: PrivatePath
    access(all) let publicLinkedType: Type
    access(all) let privateLinkedType: Type
    access(all) let collectionName: String
    access(all) let collectionDescription: String
    access(all) let collectionSquareImage: String
    access(all) let collectionBannerImage: String
    access(all) let collectionExternalURL: String
    access(all) let royalties: [MetadataViews.Royalty]

    init(
        id: UInt64,
        name: String,
        description: String,
        thumbnail: String,
        externalURL: String,
        storagePath: StoragePath,
        publicPath: PublicPath,
        privatePath: PrivatePath,
        publicLinkedType: Type,
        privateLinkedType: Type,
        collectionName: String,
        collectionDescription: String,
        collectionSquareImage: String,
        collectionBannerImage: String,
        collectionExternalURL: String,
        royalties: [MetadataViews.Royalty]
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.thumbnail = thumbnail
        self.externalURL = externalURL
        self.storagePath = storagePath
        self.publicPath = publicPath
        self.privatePath = privatePath
        self.publicLinkedType = publicLinkedType
        self.privateLinkedType = privateLinkedType
        self.collectionName = collectionName
        self.collectionDescription = collectionDescription
        self.collectionSquareImage = collectionSquareImage
        self.collectionBannerImage = collectionBannerImage
        self.collectionExternalURL = collectionExternalURL
        self.royalties = royalties
    }
}

access(all) fun main(ownerAddress: Address, collections: {String: [UInt64]}): {String: [NFT]} {
    let data: {String: [NFT]} = {}
    let account = getAuthAccount<auth(Storage,BorrowValue, IssueStorageCapabilityController, PublishCapability, SaveValue, UnpublishCapability) &Account>(ownerAddress)

    for collectionIdentifier in collections.keys {
        if NFTCatalog.getCatalogEntry(collectionIdentifier: collectionIdentifier) != nil {
            let value = NFTCatalog.getCatalogEntry(collectionIdentifier: collectionIdentifier)!
            let identifierHash = String.encodeHex(HashAlgorithm.SHA3_256.hash(collectionIdentifier.utf8))
            let tempPathStr = "catalog".concat(identifierHash)
            let tempPublicPath = PublicPath(identifier: tempPathStr)!

            let collectionCap = account.capabilities.storage.issue<&{ViewResolver.ResolverCollection}>(value.collectionData.storagePath)
            account.capabilities.publish(collectionCap, at: tempPublicPath)

            if !collectionCap.check() {
                return data
            }

            let views = NFTRetrieval.getNFTViewsFromIDs(collectionIdentifier: collectionIdentifier, ids: collections[collectionIdentifier]!, collectionCap: collectionCap)

            let items: [NFT] = []

            for view in views {
                let displayView = view.display
                let externalURLView = view.externalURL
                let collectionDataView = view.collectionData
                let collectionDisplayView = view.collectionDisplay
                let royaltyView = view.royalties

                if (displayView == nil || externalURLView == nil || collectionDataView == nil || collectionDisplayView == nil || royaltyView == nil) {
                    // Bad NFT. Skipping....
                    continue
                }

                items.append(
                    NFT(
                        id: view.id,
                        name: displayView!.name,
                        description: displayView!.description,
                        thumbnail: displayView!.thumbnail.uri(),
                        externalURL: externalURLView!.url,
                        storagePath: collectionDataView!.storagePath,
                        publicPath: collectionDataView!.publicPath,
                        privatePath: collectionDataView!.providerPath,
                        publicLinkedType: collectionDataView!.publicLinkedType,
                        privateLinkedType: collectionDataView!.providerLinkedType,
                        collectionName: collectionDisplayView!.name,
                        collectionDescription: collectionDisplayView!.description,
                        collectionSquareImage: collectionDisplayView!.squareImage.file.uri(),
                        collectionBannerImage: collectionDisplayView!.bannerImage.file.uri(),
                        collectionExternalURL: collectionDisplayView!.externalURL.url,
                        royalties: royaltyView!.getRoyalties()
                    )
                )
            }

            data[collectionIdentifier] = items
        }
    }

    return data
}
