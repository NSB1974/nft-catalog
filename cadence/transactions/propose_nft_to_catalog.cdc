import MetadataViews from "../contracts/MetadataViews.cdc"
import NFTCatalog from "../contracts/NFTCatalog.cdc"

transaction(
    collectionIdentifier : String,
    contractName: String,
    contractAddress: Address,
    nftTypeIdentifer: String,
    storagePathIdentifier: String,
    publicPathIdentifier: String,
    privatePathIdentifier: String,
    publicLinkedTypeIdentifier : String,
    publicLinkedTypeRestrictions : [String],
    privateLinkedTypeIdentifier : String,
    privateLinkedTypeRestrictions : [String],
    collectionName : String,
    collectionDescription: String,
    externalURL : String,
    squareImageMediaURL : String,
    squareImageMediaType : String,
    bannerImageMediaURL : String,
    bannerImageMediaType : String,
    socials: {String : String},
    message: String
) {

    let nftCatalogProposalResourceRef : &NFTCatalog.NFTCatalogProposalManager
    
    prepare(acct: AuthAccount) {
        
        if acct.borrow<&NFTCatalog.NFTCatalogProposalManager>(from: NFTCatalog.ProposalManagerStoragePath) == nil {
             let proposalManager <- NFTCatalog.createNFTCatalogProposalManager()
             acct.save(<-proposalManager, to: NFTCatalog.ProposalManagerStoragePath)
             acct.link<&NFTCatalog.NFTCatalogProposalManager{NFTCatalog.NFTCatalogProposalManagerPublic}>(NFTCatalog.ProposalManagerPublicPath, target: NFTCatalog.ProposalManagerStoragePath)
        }

        self.nftCatalogProposalResourceRef = acct.borrow<&NFTCatalog.NFTCatalogProposalManager>(from: NFTCatalog.ProposalManagerStoragePath)!
    }
    
    execute {
        var privateLinkedType: Type? = nil
        if (privateLinkedTypeRestrictions.length == 0) {
            privateLinkedType = CompositeType(publicLinkedTypeIdentifier)
        } else {
            privateLinkedType = RestrictedType(identifier : privateLinkedTypeIdentifier, restrictions: privateLinkedTypeRestrictions)
        }
        
        let collectionData = NFTCatalog.NFTCollectionData(
            storagePath: StoragePath(identifier: storagePathIdentifier)!,
            publicPath: PublicPath(identifier : publicPathIdentifier)!,
            privatePath: PrivatePath(identifier: privatePathIdentifier)!,
            publicLinkedType : RestrictedType(identifier : publicLinkedTypeIdentifier, restrictions: publicLinkedTypeRestrictions)!,
            privateLinkedType : privateLinkedType!
        )

        let squareMedia = MetadataViews.Media(
                        file: MetadataViews.HTTPFile(
                            url: squareImageMediaURL
                        ),
                        mediaType: squareImageMediaType
                    )
        
        let bannerMedia = MetadataViews.Media(
                        file: MetadataViews.HTTPFile(
                            url: bannerImageMediaURL
                        ),
                        mediaType: bannerImageMediaType
                    )

        let socialsStruct : {String : MetadataViews.ExternalURL} = {}
        for key in socials.keys {
            socialsStruct[key] =  MetadataViews.ExternalURL(socials[key]!)
        }
        
        let collectionDisplay = MetadataViews.NFTCollectionDisplay(
            name: collectionName,
            description: collectionDescription,
            externalURL: MetadataViews.ExternalURL(externalURL),
            squareImage: squareMedia,
            bannerImage: bannerMedia,
            socials: socialsStruct
        )

        let catalogData = NFTCatalog.NFTCatalogMetadata(
            contractName: contractName,
            contractAddress: contractAddress,
            nftType: CompositeType(nftTypeIdentifer)!,
            collectionData: collectionData,
            collectionDisplay : collectionDisplay
        )

        self.nftCatalogProposalResourceRef.setCurrentProposalEntry(identifier : collectionIdentifier)

        NFTCatalog.proposeNFTMetadata(collectionIdentifier : collectionIdentifier, metadata : catalogData, message: message, proposer: self.nftCatalogProposalResourceRef.owner!.address)

        self.nftCatalogProposalResourceRef.setCurrentProposalEntry(identifier : nil)
    }
}
import MindMastery from 0x6f27e6e32f780793
import NiftoryNonFungibleToken from 0x7ec1f607f0872a9e
import NonFungibleToken from 0x1d7e57aa55817448
import MetadataViews from 0x1d7e57aa55817448
import FlowUtilityToken from 0xead892083b3e2c6c
import FungibleToken from 0xf233dcee88fe0abe
import NFTStorefrontV2 from 0x4eb8a10cb9f87357
import TokenForwarding from 0xe544175ee0461c4b

// This transaction was auto-generated with the NFT Catalog (https://github.com/dapperlabs/nft-catalog)
//
// This transaction purchases an NFT from a dapp directly (i.e. **not** on a peer-to-peer marketplace).
// 
// Collection Identifier: MindMastery
// Vault Identifier: fut
//
// Version: 0.1.1

transaction(saleItemID: UInt64, saleItemPrice: UFix64, commissionAmount: UFix64, marketplacesAddress: [Address], expiry: UInt64, customID: String?) {
    /// "saleItemID" - ID of the NFT that is put on sale by the seller.
    /// "saleItemPrice" - Amount of tokens (FT) buyer needs to pay for the purchase of listed NFT.
    /// "commissionAmount" - Commission amount that will be taken away by the purchase facilitator.
    /// "marketplacesAddress" - List of addresses that are allowed to get the commission.
    /// "expiry" - Unix timestamp at which created listing become expired.
    /// "customID" - Optional string to represent identifier of the dapp.
    let sellerPaymentReceiver: Capability<&{FungibleToken.Receiver}>
    let nftProvider: Capability<&MindMastery.Collection{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}>
    let storefront: &NFTStorefrontV2.Storefront
    var saleCuts: [NFTStorefrontV2.SaleCut]
    var marketplacesCapability: [Capability<&AnyResource{FungibleToken.Receiver}>]

    // It's important that the dapp account authorize this transaction so the dapp has the ability
    // to validate and approve the royalty included in the sale.
    prepare(seller: AuthAccount) {
        self.saleCuts = []
        self.marketplacesCapability = []

        // If the account doesn't already have a storefront, create one and add it to the account
        if seller.borrow<&NFTStorefrontV2.Storefront>(from: NFTStorefrontV2.StorefrontStoragePath) == nil {
            // Create a new empty Storefront
            let storefront <- NFTStorefrontV2.createStorefront() as! @NFTStorefrontV2.Storefront
            // save it to the account
            seller.save(<-storefront, to: NFTStorefrontV2.StorefrontStoragePath)
            // create a public capability for the Storefront
            seller.link<&NFTStorefrontV2.Storefront{NFTStorefrontV2.StorefrontPublic}>(NFTStorefrontV2.StorefrontPublicPath, target: NFTStorefrontV2.StorefrontStoragePath)
        }
        

         // FT Setup if the user's account is not initialized with FT receiver
        if seller.borrow<&{FungibleToken.Receiver}>(from: /storage/flowUtilityTokenReceiver) == nil {

            let dapper = getAccount(0xead892083b3e2c6c)
            let dapperFTReceiver = dapper.getCapability<&{FungibleToken.Receiver}>(/public/flowUtilityTokenReceiver)!

            // Create a new Forwarder resource for FUT and store it in the new account's storage
            let ftForwarder <- TokenForwarding.createNewForwarder(recipient: dapperFTReceiver)
            seller.save(<-ftForwarder, to: /storage/flowUtilityTokenReceiver)

            // Publish a Receiver capability for the new account, which is linked to the FUT Forwarder
            seller.link<&FlowUtilityToken.Vault{FungibleToken.Receiver}>(
                /public/flowUtilityTokenReceiver,
                target: /storage/flowUtilityTokenReceiver
            )
        }

        // Get a reference to the receiver that will receive the fungible tokens if the sale executes.
        // Note that the sales receiver aka MerchantAddress should be an account owned by Dapper or an end-user Dapper Wallet account address.
        self.sellerPaymentReceiver = getAccount(seller.address).getCapability<&{FungibleToken.Receiver}>(/public/flowUtilityTokenReceiver)
        assert(self.sellerPaymentReceiver.borrow() != nil, message: "Missing or mis-typed DapperUtilityCoin receiver")

        // If the user does not have their collection linked to their account, link it.
        if seller.borrow<&MindMastery.Collection>(from: /storage/clz0456d70001jv0vub7939aq_MindMastery_nft_collection) == nil {
            let collection <- MindMastery.createEmptyCollection()
            seller.save(<-collection, to: /storage/clz0456d70001jv0vub7939aq_MindMastery_nft_collection)
        }
        if (seller.getCapability<&MindMastery.Collection{NiftoryNonFungibleToken.CollectionPublic,NonFungibleToken.CollectionPublic,NonFungibleToken.Receiver,MetadataViews.ResolverCollection}>(/public/clz0456d70001jv0vub7939aq_MindMastery_nft_collection).borrow() == nil) {
            seller.unlink(/public/clz0456d70001jv0vub7939aq_MindMastery_nft_collection)
            seller.link<&MindMastery.Collection{NiftoryNonFungibleToken.CollectionPublic,NonFungibleToken.CollectionPublic,NonFungibleToken.Receiver,MetadataViews.ResolverCollection}>(/public/clz0456d70001jv0vub7939aq_MindMastery_nft_collection, target: /storage/clz0456d70001jv0vub7939aq_MindMastery_nft_collection)
        }

        if (seller.getCapability<&MindMastery.Collection{NiftoryNonFungibleToken.CollectionPublic,NonFungibleToken.CollectionPublic,NonFungibleToken.Provider,MetadataViews.ResolverCollection}>(/private/clz0456d70001jv0vub7939aq_MindMastery_nft_collection).borrow() == nil) {
            seller.unlink(/private/clz0456d70001jv0vub7939aq_MindMastery_nft_collection)
            seller.link<&MindMastery.Collection{NiftoryNonFungibleToken.CollectionPublic,NonFungibleToken.CollectionPublic,NonFungibleToken.Provider,MetadataViews.ResolverCollection}>(/private/clz0456d70001jv0vub7939aq_MindMastery_nft_collection, target: /storage/clz0456d70001jv0vub7939aq_MindMastery_nft_collection)
        }

        self.nftProvider = seller.getCapability<&MindMastery.Collection{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}>(/private/clz0456d70001jv0vub7939aq_MindMastery_nft_collection)!
        assert(self.nftProvider.borrow() != nil, message: "Missing or mis-typed collection provider")

        if seller.borrow<&NFTStorefrontV2.Storefront>(from: NFTStorefrontV2.StorefrontStoragePath) == nil {
            // Create a new empty Storefront
            let storefront <- NFTStorefrontV2.createStorefront() as! @NFTStorefrontV2.Storefront
            // save it to the account
            seller.save(<-storefront, to: NFTStorefrontV2.StorefrontStoragePath)
            // create a public capability for the Storefront
            seller.link<&NFTStorefrontV2.Storefront{NFTStorefrontV2.StorefrontPublic}>(NFTStorefrontV2.StorefrontPublicPath, target: NFTStorefrontV2.StorefrontStoragePath)
        }
        self.storefront = seller.borrow<&NFTStorefrontV2.Storefront>(from: NFTStorefrontV2.StorefrontStoragePath)
            ?? panic("Missing or mis-typed NFTStorefront Storefront")

        
        let collectionRef = seller
            .getCapability(/public/clz0456d70001jv0vub7939aq_MindMastery_nft_collection)
            .borrow<&MindMastery.Collection{NiftoryNonFungibleToken.CollectionPublic,NonFungibleToken.CollectionPublic,NonFungibleToken.Receiver,MetadataViews.ResolverCollection}>()
            ?? panic("Could not borrow a reference to the collection")
        var totalRoyaltyCut = 0.0
        let effectiveSaleItemPrice = saleItemPrice - commissionAmount

        let nft = collectionRef.borrowViewResolver(id: saleItemID)!       
        if (nft.getViews().contains(Type<MetadataViews.Royalties>())) {
            let royaltiesRef = nft.resolveView(Type<MetadataViews.Royalties>()) ?? panic("Unable to retrieve the royalties")
            let royalties = (royaltiesRef as! MetadataViews.Royalties).getRoyalties()
            for royalty in royalties {
                // TODO - Verify the type of the vault and it should exists
                self.saleCuts.append(NFTStorefrontV2.SaleCut(receiver: royalty.receiver, amount: royalty.cut * effectiveSaleItemPrice))
                totalRoyaltyCut = totalRoyaltyCut + royalty.cut * effectiveSaleItemPrice
            }
        }

        // Append the cut for the seller.
        self.saleCuts.append(NFTStorefrontV2.SaleCut(
            receiver: self.sellerPaymentReceiver,
            amount: effectiveSaleItemPrice - totalRoyaltyCut
        ))

        for marketplace in marketplacesAddress {
            self.marketplacesCapability.append(getAccount(marketplace).getCapability<&{FungibleToken.Receiver}>(/public/flowUtilityTokenReceiver))
        }
    }

    execute {

         self.storefront.createListing(
            nftProviderCapability: self.nftProvider,
            nftType: Type<@MindMastery.NFT>(),
            nftID: saleItemID,
            salePaymentVaultType: Type<@FlowUtilityToken.Vault>(),
            saleCuts: self.saleCuts,
            marketplacesCapability: self.marketplacesCapability.length == 0 ? nil : self.marketplacesCapability,
            customID: customID,
            commissionAmount: commissionAmount,
            expiry: expiry
        )
    }
}
