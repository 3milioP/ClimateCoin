// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

//Se importan los interfaces de la librería openzeppelin que son necesarios para el contrato
import {ERC1155} from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import {ERC1155Burnable} from "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import {ERC1155Supply} from "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC1155Receiver} from "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol"; // Importamos la interfaz
//Esto de counters no lo habíamos dado en clase, pero me ha parecido bien incluirlo para la identificación de cada NFT
import {Counters} from "@openzeppelin/contracts/utils/Counters.sol";

//Aplicamos la interfaz al contrato
contract ClimateCoin is ERC1155, Ownable, ERC1155Burnable, ERC1155Supply, IERC1155Receiver {
    using Counters for Counters.Counter;

    // Contador para IDs de proyectos
    Counters.Counter private _projectIds; //Según leí, el "guión bajo" antes del nombre indica que es variable interna

    // Fee en porcentaje
    uint256 public feePercentage = 2;

    // las siguientes dos funciones son obligatorias debido a la implementación de la interfaz IERC1155Reciever
    // que prepara nuestro contrato para que sea capaz de recibir tokens 1155
    function onERC1155Received(
    address /*operator*/,
    address /*from*/,
    uint256 /*id*/,
    uint256 /*value*/,
    bytes memory /*data*/
    ) public pure override returns (bytes4) {
    return this.onERC1155Received.selector;
    }
    // Se comentan las variables porque daba un warning
    function onERC1155BatchReceived(
    address /*operator*/,
    address /*from*/,
    uint256[] memory /*ids*/,
    uint256[] memory /*values*/,
    bytes memory /*data*/
    ) public pure override returns (bytes4) {
    return this.onERC1155BatchReceived.selector;
    }

    // Estructura para metadatos de proyectos
    struct ProjectMetadata {
        string name;
        string url;
        uint256 totalCredits;
        address companyAddress;  // Dirección de la empresa asociada
    }
    //HashMap para asociar el struct de metadatos a un proyecto
    mapping(uint256 => ProjectMetadata) public projectDetails;

    // Eventos útiles para facilitar su trazabilidad
    //El uso de "indexed" tampoco lo hemos visto aún en las clases, tal como he leído
    // facilita el reastreo de eventos ya que quedan indexados en logs de la blockchain fácilmente accesibles desde exploradores de bloques
    event ProjectCreated(uint256 indexed projectId, string name, string url, uint256 totalCredits);
    event NFTExchanged(address indexed developer, uint256 projectId, uint256 creditsExchanged, uint256 fee);
    event URIUpdated(string newURI);
    event TokenBurned(address indexed burner, uint256 tokenId, uint256 amount);
    event AddressUpdated(address newCompanyAddress);

    constructor(address initialOwner) ERC1155("") Ownable(initialOwner) {}

    /// Función para obtener el nombre del token, como es un ERC-1155 lo hacemos así
    function name() public pure returns (string memory) {
        return "CCO"; // El nombre del token es "CCO"
    }

    // Función para obtener el símbolo del token
    function symbol() public pure returns (string memory) {
        return "CCO"; // El símbolo del token es "CCO"
    }

    // Función para establecer URI, solo puede actualizar el dueño del proyecto
    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
        emit URIUpdated(newuri);
    }

    // Función para crear un proyecto (minteo único de NFT + fungibles)
    function createProject(
    string memory projectName,
    string memory url,
    uint256 totalCredits,
    address companyAddress // Dirección de la empresa que recibirá el NFT
    ) external onlyOwner {
    _projectIds.increment();
    uint256 newProjectId = _projectIds.current();

    // Registrar detalles del proyecto
    projectDetails[newProjectId] = ProjectMetadata(projectName, url, totalCredits, companyAddress);

    // Mintear NFT único para el proyecto, un id para un solo token. Esto hace un NFT único
    _mint(msg.sender, newProjectId, 1, ""); // NFT

    // Transferir el NFT a la dirección de la empresa
    safeTransferFrom(msg.sender, companyAddress, newProjectId, 1, ""); // La empresa recibe el NFT

    emit ProjectCreated(newProjectId, projectName, url, totalCredits);
    }
    // Función para modificar la dirección de la empresa asociada al proyecto
    function setCompanyAddress(uint256 projectId, address newCompanyAddress) external onlyOwner {
    require(projectDetails[projectId].companyAddress != address(0), "Proyecto no existe");
    projectDetails[projectId].companyAddress = newCompanyAddress;
    emit AddressUpdated(newCompanyAddress);
    }

    function exchangeNFTForCredits(uint256 projectId) external {
    uint256 nftId = projectId;
    uint256 fungibleTokenId = projectId + 1000; //Diferenciamos el ID del NFT del de los tokens

    // Verificar que el usuario tiene el NFT
    require(balanceOf(msg.sender, nftId) > 0, "No eres el propietario del NFT");

    // Obtener créditos totales del proyecto
    uint256 creditsToMint = projectDetails[projectId].totalCredits;

    // Calcular fee
    uint256 fee = (creditsToMint * feePercentage) / 100;
    uint256 creditsAfterFee = creditsToMint - fee;

    // Transferir el NFT al contrato (esto "quema" el NFT, ya que lo transfiere al contrato)
    safeTransferFrom(msg.sender, address(this), nftId, 1, ""); // El contrato recibe el NFT

    // Quemar el NFT
    _burn(address(this), nftId, 1); // El contrato quema el NFT recibido

    //Los tokens se mintean al momento
    // Mintear los ClimateCoins (tokens fungibles) para el desarrollador
    _mint(msg.sender, fungibleTokenId, creditsAfterFee, ""); // El desarrollador recibe los ClimateCoins

    // Mintear el fee y enviarlo al owner del contrato
    _mint(owner(), fungibleTokenId, fee, ""); // El owner recibe el fee

    emit NFTExchanged(msg.sender, projectId, creditsAfterFee, fee);
    }   

    // Función para quemar los ClimateCoins solo si la dirección es la de la empresa asociada
    function burnClimateCoin(uint256 projectId, uint256 tokenId, uint256 amount) external {
    address companyAddress = projectDetails[projectId].companyAddress;
    // Verificar que la persona que llama a la función es la empresa asociada a ese proyecto
    require(msg.sender == companyAddress, "Solo la empresa asociada puede quemar los ClimateCoins");

    // Llamar al método _burn de ERC1155 para quemar los tokens
    _burn(msg.sender, tokenId, amount);
    
    // Emitir un evento para registrar la quema
    emit TokenBurned(msg.sender, tokenId, amount);
    }   

    // Actualizar fee
    function setFeePercentage(uint256 newFeePercentage) external onlyOwner {
        feePercentage = newFeePercentage;
    }

    // La siguiente función es un override requerido por Solidity.
    function _update(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory values
    ) internal override(ERC1155, ERC1155Supply) {
        super._update(from, to, ids, values);
    }
}
