workspace {

    model {
        properties {
            "structurizr.groupSeparator" "/"
        }

        group "RECRD Ecosystem" {
            recrdAdmin = person "RECRD Administrator" "The RECRD Admin responsible for managing and securing custodial wallets and on-chain assets (Profiles and Masters)." "SystemActor"
            recrd = softwareSystem "RECRD App System" "Platform for viewing and creating user-generated content. On its Web 3.0 aspect it offers an in-app marketplace for trading user content's on chain represented assets (Masters) and functionalities for their lifecycle management, and for on-chain tracking of users activity (Profiles)." "MainSystem" {

                database = container "Database" "The main Database entity for the RECRD platform" "Managed Cassandra Service" "Database"
                group "RECRD Wen 2.0 Backend" {

                    microserviceX = container "MicroService X" "Indicates the variety of RECRD's microservices serving different business needs" "Java/Spring Boot" "Service"
                    paymentsService = container "Lena - Payments Service" "The service responsible for handling payments (Ad-revenues, marketplace fiat payments etc.)" "Java/Spring Boot" "SecondaryService, Service"
                    web3IntegrationService = container "Salado - Blockchain integration service" "Service responsible for creating custodial wallets and applying smart contract calls for updaing UserPorfile and Master on-chain assets" "NodeJS/Sui TS SDK" "MainService, Service"
                }
                group "RECRD Apps" {
                    recrdAndroidApp = container "RECRD Android App" "Native Android RECRD app with Enoki and Blockchain integration capabilities" "Kotlin/Sui Mobile SDK" "MobileApp"
                    recrdIOSApp = container "RECRD iOS App" "Native iOS RECRD app with Enoki and Blockchain integration capabilities" "Swift/Sui Mobile SDK" "MobileApp"
                    recrdWebApp = container "RECRD Web App" "RECRD web app with Enoki and Blockchain integration capabilities" "ReactJs/Sui TS SDK" "WebApp"
                }
                smartContract = container "Smart Contract" "Contains modules for minting and managing Profile and Master on-chain assets" "Move on Sui" "SmartContract" {
                    coreModule = component "Core Module" "Reference module that handles the AdminCap object." "Move Module" "Move Module"
                    masterModule = component "Master Module" "Module for minting and burning Master objects and their associated Metadata." "Move Module" "Move Module"
                    profileModule = component "Profile Module" "Module for minting Porfile objects and handling the trading lifecycle of Masters." "Move Module" "Move Module"
                    receiptModule = component "Receipt Module" "Helper module for minting and burning the assets trading assistant Receipt object." "Move Module" "Move Module"

                    promiseStruct = component "Promise" "A Move struct which acts as a Hot-Potato for the borrowing assets flow" "Move Struct" "Move Struct"
                    videoStruct = component "Video" "Struct to indicate an option of a Matser's type" "Move Struct" "Move Struct"
                    soundStruct = component "Sound" "Struct to indicate an option of a Matser's type" "Move Struct" "Move Struct"
                }
            }
        }
        group "RECRD Platform User Types" {
            visitor = person "Unregistered User" "Unregistered user who watches videos and ads using the mobile or desktop app without a connected account." "VisitorActor"
            registeredUser = person "Registered User" "Registered user who watches videos and ads using the mobile or desktop app and buy on-chain assets from the app marketplace" "UserActor"
            creator = person "Creator User" "Registered user who actively participates by uploading Videos and Sounds (aka. Masters) to the platform and can list them as on-chain for-sale asset in the app marketplace." "CreatorActor"
            privateUser = person "Private User" "Creator who selects his profile visibility, uploaded content and marketplace assets to be visible only on subscribed audience" "UserActor"
        }

        enoki = softwareSystem "Enoki SaaS Platform" "Used for creating Enoki wallets for creators and for sponsoring transactions."
        sui = softwareSystem "Sui Blockchain" "The platform for the smart contract execution for the user profile and user assets management, storage and exchange." "Blockchain" {
            recrdAssets = container "RECRD Assets" "Indicates the assets stored on chain for the RECRD platform." "Assets" {
                adminCapObj = component "AdminCap" "The Admin Capability transfered to the Recrd Admin during publishing the contract. More instances can further be minted and passed by the orignal admin." "Move Owned Object" "Move Struct"
                masterObj = component "Master<T>" "The basic tradeable asset that represents user generated content on chain, owned by the Profile object on behalf of the user." "Move Owned Object" "Move Struct"
                metadataObj = component "Metadata<T>" "Companion to the Master object, owned by the Recrd Admin in order to be able to manage user on-chain assets as per business, regulation or any other rules." "Move Owned Object" "Move Struct"
                profileObj = component "Profile" "Shared object that acts as a wallet abstraction which stores assets (Masters) on the user's bahalf. Operations on this object allowed by commiting an associated Receipt or by having been whitelisted by an AdminCap Owner." "Move Shared Object" "Move Struct"
                receiptObj = component "Receipt" "Short-lived object that is being assigned to a user from an AdminCap owner and used as a proof of payment for an assets trading operation." "Move Owned Object" "Move Struct"
            }
        }

        # relationships between people and software systems
        recrdAdmin -> sui "Contracts publisher, AdminCap owner for minting and managing Profiles and Masters on chain."
        recrdAdmin -> recrd "Manages users and payments through the platform's backoffice services."
        recrd -> sui "Integrates with the published Smart Contract to mint and manage Profiles and Masters."
        recrd -> enoki "Integrates with Enoki Services for generating Enoki wallets, proving signatures intengrity and sponsoring on-chain transactions on behalf of users."
        visitor -> recrd "Visits RECRD app page and/or mobile app to watch videos without registering. Upon the first landing to the app a custodial wallet is being created and an associated Profile Object is minted by the platform on their behalf."
        userrel1 = visitor -> registeredUser "Becomes one, once they chose to register into the platform. In case they register with an Enoki compatible method, an Enoki wallet is automatically been generated for them."
        registeredUser -> recrd "Uses the RECRD App in order to watch videos with a registered account. Session activity is being tracked on chain by Profile Object's updates."
        userrel2 = registeredUser -> creator "Becomes one, once they choose to start uploading owned content into the platform. When decides to paritcipate in the RECRD marketplace for trading Masters they use an existing Enoki wallet if present or prompted to create one within the app."
        userrel3 = creator -> privateUser "Becomes one, if they chose to hide their presence and content from the public audience."
        creator -> recrd "Uses the RECRD App in order to upload and publish content and potentially list and trade content, as on-chain assets, through the in-app marketplace."

        # relationships to/from containers
        visitor -> recrdAndroidApp "Uses the app to watch videos and ads."
        registeredUser -> recrdAndroidApp "Uses the app to watch videos and ads and buy assets through the marketplace."
        creator -> recrdAndroidApp "Uses the app to watch videos and ads and upload own content and trade assets through the marketplace."

        recrdWebApp -> enoki "Integrates with the service to create Enoki wallets for currently unregistered RECRD users who register with a compatible method into the platform."
        recrdWebApp -> enoki "Integrates with the service to create Enoki wallets for registered RECRD user when they attempt to use the marketplace features."
        recrdWebApp -> enoki "Integrates with the service to get the sponsor's signature for executing transactions on chain."

        smartContract -> sui "Published On"
        web3IntegrationService -> sui "Creates custodial wallets for unregistered and existing users."
        web3IntegrationService -> smartContract "Calls functions for minting and managing UserPorfile and Master assets."

        microserviceX -> paymentsService "Integrates with for RECRD mainstream business flows, i.e. creators' ad revenue compensation and on-chain flows, i.e. marketplace assets trading payments."
        microserviceX -> web3IntegrationService "Triggers calls for Profile minting and further management."
        microserviceX -> web3IntegrationService "Triggers calls for Master minting, listing for sale and further management."
        paymentsService -> web3IntegrationService "Triggers calls upon payments received for marketplace trades.

        recrdWebApp -> microserviceX "Integrates with the various RECRD business services through a REST API."
        microserviceX -> database "Read/Write operations for the associated RECRD business entities."

        # relationships to/from components
        masterModule -> coreModule "Depends On"
        receiptModule -> coreModule "Depends On"
        profileModule -> coreModule "Depends On"
        profileModule -> masterModule "Depends On"
        profileModule -> receiptModule "Depends On"
        promiseStruct -> profileModule "Implemented In"
        videoStruct -> masterModule "Implemented In"
        soundStruct -> masterModule "Implemented In"

        recrdAdmin -> adminCapObj "Owns the initial instance and can generate and transfer new instances."
        recrdAdmin -> receiptobj "Mints and transfer to user upon a payment completion."

        profileObj -> masterObj "Owns through the Sui Transfer to Object feature."
        masterObj -> metadataObj "One to one association"
        receiptRel1 = creator -> receiptobj "Used as a witness of payment for buying on-chain assets."
        receiptRel2 = registeredUser -> receiptobj "Used as a witness of payment for buying on-chain assets."
        profileRel1 = profileObj -> creator "Managed wallet abstraction for indicating user owned Masters."
        profileRel2 = profileObj -> registeredUser "Managed wallet abstraction for indicating user owned Masters."
    }

    views {

        systemlandscape "SystemLandscape" {
            include *
            exclude receiptRel1
            exclude receiptRel2
            exclude profileRel1
            exclude profileRel2
            autoLayout lr
        }

        systemcontext recrd "SystemContext" {
            include *
            exclude receiptRel1
            exclude receiptRel2
            exclude profileRel1
            exclude profileRel2
            autoLayout lr
            description "The system context diagram for the RECRD App."
            properties {
                structurizr.groups true
            }
        }

        container recrd "RECRDContainer" {
            include *
            exclude userrel1
            exclude userrel2
            exclude userrel3
            exclude receiptRel1
            exclude receiptRel2
            exclude profileRel1
            exclude profileRel2
//            autoLayout lr
            description "The container diagram for the RECRD Platform ecosystem."
            properties {
                structurizr.groups true
            }
        }

        component smartContract "SmartContract" {
            include *
            autoLayout
            description "The component diagram for the smart contract."
        }

        component recrdAssets "RECRDAssets" {
            include *
            exclude userrel1
            exclude userrel2
            exclude userrel3
//            autoLayout
            description "The component diagram for the on-chain assets."
        }

        branding {
            logo "https://tk-storage.s3.ap-southeast-1.amazonaws.com/host/investor/Mys_20221202035736.jpeg"
        }

        styles {
            relationship "Relationship" {
//                width 500
            }

            element "Element" {
                width 750
                height 500
                fontSize 30
            }

            element "SystemActor" {
                shape person
                background #08427b
                color #ffffff
            }

            element "CreatorActor" {
                shape person
                background #1168bd
                color #ffffff
            }

            element "UserActor" {
                shape person
            }

            element "VisitorActor" {
                shape person
            }

            element "MainSystem" {
                background #08427b
                color #ffffff
                shape RoundedBox
            }

            element "Blockchain" {
                background #08427b
                color #ffffff
                icon "https://s2.tokeninsight.com/static/coins/img/content/imgUrl/sui_logo.png"
                shape Pipe
            }

            element "Database" {
                color #ffffff
                background #1168bd
                shape Cylinder
            }

            element "WebApp" {
                background #1168bd
                color #ffffff
                shape WebBrowser
            }

            element "MobileApp" {
                background #1168bd
                color #ffffff
                shape MobileDevicePortrait
            }

            element Service {
                shape RoundedBox
            }

            element "MainService" {
                color #ffffff
                background #08427b
            }

            element "SecondaryService" {
                color #ffffff
                background #1168bd
            }

            element "SmartContract" {
                color #ffffff
                background #08427b
                shape Ellipse
            }

            element "Move Module" {
                shape Hexagon
            }

            element "Move Struct" {
                color #ffffff
                background #08427b
                shape Component
            }
        }
    }
}