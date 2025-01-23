// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {ERC1155} from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import {ERC1155Burnable} from "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import {ERC1155Supply} from "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Counters} from "@openzeppelin/contracts/utils/Counters.sol";

contract ClimateCoin is ERC1155, Ownable, ERC1155Burnable, ERC1155Supply {
    using Counters for Counters.Counter;

    // Contador para IDs de proyectos
    Counters.Counter private _projectIds;

    // Fee en porcentaje
    uint256 public feePercentage = 2;

    // Estructura para metadatos de proyectos
    struct ProjectMetadata {
        string name;
        string url;
        uint256 totalCredits;
    }

    mapping(uint256 => ProjectMetadata) public projectDetails;

    // Eventos
    event ProjectCreated(uint256 indexed projectId, string name, string url, uint256 totalCredits);
    event NFTExchanged(address indexed developer, uint256 projectId, uint256 creditsExchanged, uint256 fee);
    event URIUpdated(string newURI);

    constructor(address initialOwner) ERC1155("") Ownable(initialOwner) {}

    // Función para establecer URI
    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
        emit URIUpdated(newuri);
    }

    // Función para crear un proyecto (minteo único de NFT + fungibles)
    function createProject(
        string memory name,
        string memory url,
        uint256 totalCredits
    ) external onlyOwner {
        _projectIds.increment();
        uint256 newProjectId = _projectIds.current();

        // Registrar detalles del proyecto
        projectDetails[newProjectId] = ProjectMetadata(name, url, totalCredits);

        // Mintear NFT único para el proyecto
        _mint(msg.sender, newProjectId, 1, ""); // NFT

        // Mintear créditos fungibles para el proyecto
        _mint(msg.sender, newProjectId + 1000, totalCredits, ""); // Créditos fungibles

        emit ProjectCreated(newProjectId, name, url, totalCredits);
    }

    // Minteo manual
    function mint(
        address account,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public onlyOwner {
        _mint(account, id, amount, data);
    }

    // Minteo en lote
    function mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public onlyOwner {
        _mintBatch(to, ids, amounts, data);
    }

    // Intercambio de NFT por créditos ClimateCoin
    function exchangeNFTForCredits(uint256 projectId) external {
        uint256 nftId = projectId;
        uint256 fungibleTokenId = projectId + 1000;

        // Verificar que el usuario tiene el NFT
        require(balanceOf(msg.sender, nftId) > 0, "You do not own this NFT");

        // Obtener créditos totales del proyecto
        uint256 creditsToMint = projectDetails[projectId].totalCredits;

        // Calcular fee
        uint256 fee = (creditsToMint * feePercentage) / 100;
        uint256 creditsAfterFee = creditsToMint - fee;

        // Transferir el NFT al contrato
        safeTransferFrom(msg.sender, address(this), nftId, 1, "");

        // Transferir créditos al usuario y fee al owner
        _mint(msg.sender, fungibleTokenId, creditsAfterFee, "");
        _mint(owner(), fungibleTokenId, fee, "");

        emit NFTExchanged(msg.sender, projectId, creditsAfterFee, fee);
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
