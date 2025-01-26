# ClimateCoin: Proyecto DApp de Créditos de Carbono

## Descripción

ClimateCoin es una DApp que permite el intercambio de créditos de carbono mediante el uso de NFTs y tokens fungibles en la blockchain. Este sistema facilita la compensación de emisiones de CO2 mediante el uso de ClimateCoins (CC), un token ERC-1155. Los créditos de carbono son representados por un NFT ERC-1155, el cual puede ser intercambiado por ClimateCoins, y luego quemado para simbolizar la compensación de CO2.

## Flujo del Proyecto

1. **Certificación del Proyecto**: Un desarrollador instala paneles solares y recibe créditos de carbono certificados por plataformas como [Ecoregistry](https://www.ecoregistry.io).
2. **Creación del NFT**: El desarrollador transfiere los créditos al contrato ClimateCoin, y el sistema emite un NFT ERC-1155 representando el proyecto y los créditos de carbono.
3. **Intercambio por ClimateCoin**: El desarrollador intercambia el NFT por ClimateCoins (CC), donde 1 CC equivale a 1 crédito de carbono. Una pequeña fee se cobra en el proceso.
4. **Comercio en Mercados Externos**: Los ClimateCoins pueden ser vendidos en mercados externos.
5. **Quema de ClimateCoins**: Cualquier usuario puede "quemar" sus ClimateCoins y retirar créditos de carbono del mercado.

## Características

- **ERC-1155**: Los créditos de carbono son representados como tokens ERC-1155, lo que permite representar tanto fungibles como no fungibles en un único contrato.
- **Sistema de Fees**: Un porcentaje de cada intercambio de NFT por ClimateCoins es retenido como fee.
- **URI Dinámico**: Se puede actualizar la URI para los metadatos de los tokens.

## Contrato Inteligente

Este contrato implementa un sistema de **ERC-1155** para representar los créditos de carbono y ClimateCoins, con las siguientes funciones clave:

### Funciones Principales

- **`createProject(string memory name, string memory url, uint256 totalCredits)`**: Crea un nuevo proyecto de créditos de carbono, mintando un NFT y asignando créditos fungibles.
- **`exchangeNFTForCredits(uint256 projectId)`**: Intercambia el NFT por ClimateCoins, descontando una fee.
- **`mint(address account, uint256 id, uint256 amount, bytes memory data)`**: Permite al propietario del contrato mintear nuevos tokens.
- **`setFeePercentage(uint256 newFeePercentage)`**: Permite al propietario del contrato ajustar el porcentaje de la fee.
- **`setURI(string memory newuri)`**: Permite al propietario del contrato actualizar la URI base de los metadatos de los tokens.

### Funciones de OpenZeppelin

El contrato también utiliza extensiones de OpenZeppelin, tales como:
- **`ERC1155Burnable`**: Permite la quema de tokens.
- **`ERC1155Supply`**: Habilita el seguimiento de la oferta total de cada token.
- **`Ownable`**: Asegura que solo el propietario del contrato pueda ejecutar ciertas funciones (como mintear tokens y actualizar la fee).

## Ejemplo de uso

1. **Crear un proyecto de créditos de carbono**:

   El propietario del contrato puede crear un nuevo proyecto con:

    ```solidity
    climateCoin.createProject("Proyecto Solar Colombia", "https://www.ecoregistry.io/projects/151", 297565);
    ```

2. **Intercambiar NFT por ClimateCoins**:

   Un usuario puede intercambiar un NFT por ClimateCoins de la siguiente manera:

    ```solidity
    climateCoin.exchangeNFTForCredits(1);
    ```

## Eventos

El contrato emite los siguientes eventos para facilitar la trazabilidad:

- **`ProjectCreated(uint256 indexed projectId, string name, string url, uint256 totalCredits)`**: Emitido cuando un nuevo proyecto es creado.
- **`NFTExchanged(address indexed developer, uint256 projectId, uint256 creditsExchanged, uint256 fee)`**: Emitido cuando un NFT es intercambiado por ClimateCoins.
- **`URIUpdated(string newURI)`**: Emitido cuando la URI base de los tokens es actualizada.

## Seguridad

- **Verificación de Propietario**: Solo el propietario del contrato puede mintear tokens y cambiar la configuración (por ejemplo, la fee).
- **Verificación de Saldo de NFTs**: Al intercambiar un NFT, se verifica que el usuario realmente posea el NFT antes de proceder.

Este proyecto está bajo la Licencia MIT - ver el archivo [LICENSE](LICENSE) para más detalles.

## Contacto

- **Email**: emilioperezarjona@gmail.com
- **GitHub**: [https://github.com/3milioP](https://github.com/3milioP)

