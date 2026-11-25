"""校验题库编号、章节、具体亚类、作用靶点机制、分子连接、分子式、电荷与立体信息。"""

from __future__ import annotations

import json
import re
from pathlib import Path
from urllib.request import Request, urlopen

from rdkit import Chem
from rdkit.Chem import rdCIPLabeler, rdMolDescriptors
from rdkit.Chem.MolStandardize import rdMolStandardize

ROOT = Path(__file__).resolve().parent.parent
EXPECTED_COUNT = 232
ENHANCED_CIS_IDS = {"83", "136", "220"}
STEREOISOMER_CONN_PAIRS = {frozenset({"191", "229"})}
CISPLATIN_ID = "223"
CISPLATIN_STEREO_SMILES = "[NH3]->[Pt@SP3](<-[NH3])([Cl])[Cl]"

STANDARD_CHAPTERS = (
    "镇静催眠药与抗癫痫药",
    "抗精神病药",
    "抗抑郁药",
    "镇痛药",
    "神经退行性疾病、麻醉与中枢兴奋药",
    "拟胆碱、抗胆碱与拟肾上腺素药",
    "抗过敏药",
    "抗高血压药",
    "利尿药",
    "抗心律失常与抗心绞痛药",
    "调血脂药",
    "抗凝血与抗血小板药",
    "消化系统药物",
    "解热镇痛、非甾体抗炎及抗痛风药",
    "抗肿瘤药",
    "抗生素",
    "合成抗菌药",
    "抗结核药",
    "抗真菌药",
    "抗病毒药",
    "抗寄生虫药",
    "降血糖药",
    "甾体激素类药物",
    "维生素",
)


def parse_formula_counts(formula: str) -> dict[str, int]:
    cleaned = formula.rstrip("+-0123456789") if ("+" in formula or "-" in formula) else formula
    counts: dict[str, int] = {}
    for elem, num in re.findall(r"([A-Z][a-z]?)(\d*)", cleaned):
        counts[elem] = counts.get(elem, 0) + (int(num) if num else 1)
    return counts


def load_live_properties(references: list[dict]) -> dict[int, dict]:
    cids = ",".join(str(item["cid"]) for item in references)
    url = (
        "https://pubchem.ncbi.nlm.nih.gov/rest/pug/compound/cid/"
        f"{cids}/property/IsomericSMILES,CanonicalSMILES,MolecularFormula,Charge/JSON"
    )
    request = Request(url, headers={"User-Agent": "drug-structure-review/4.3"})
    with urlopen(request, timeout=60) as response:
        payload = json.load(response)
    return {item["CID"]: item for item in payload["PropertyTable"]["Properties"]}


def canonical(mol: Chem.Mol, drug_id: str) -> str:
    actual = mol
    if drug_id == "22":
        actual = rdMolStandardize.TautomerEnumerator().Canonicalize(mol)
    return Chem.MolToSmiles(actual, isomericSmiles=True)


def validate_drug(item: dict, reference: dict) -> Chem.Mol:
    label = f"{item['id']} {item['name']}"
    mol = Chem.MolFromSmiles(item["smiles"])
    source = Chem.MolFromSmiles(
        reference.get("stereoReferenceSmiles", reference["referenceSmiles"])
    )
    if mol is None or source is None:
        raise ValueError(f"{label}：SMILES 解析失败")
    formula = rdMolDescriptors.CalcMolFormula(mol)
    if formula != reference["formula"]:
        if item["id"] != CISPLATIN_ID or parse_formula_counts(formula) != parse_formula_counts(
            reference["formula"]
        ):
            raise ValueError(f"{label}：分子式须与来源记录一致（实际 {formula} vs {reference['formula']}）")
    if item["id"] == CISPLATIN_ID and canonical(mol, item["id"]) != CISPLATIN_STEREO_SMILES:
        raise ValueError(f"{label}：顺铂须保持平面四配位顺式构型")
    if canonical(mol, item["id"]) != canonical(source, item["id"]):
        raise ValueError(f"{label}：连接或立体表达需与来源核对")
    if Chem.GetFormalCharge(mol) != reference["formalCharge"]:
        raise ValueError(f"{label}：电荷须与选定形态一致")
    rdCIPLabeler.AssignCIPLabels(mol)
    centers = Chem.FindMolChiralCenters(
        mol, includeUnassigned=True, useLegacyImplementation=False
    )
    unassigned = [index for index, tag in centers if tag == "?"]
    if unassigned != reference["unassignedCenters"]:
        raise ValueError(f"{label}：待指定手性中心须与临床形态记录一致")
    if unassigned and reference["racemate"] is False:
        raise ValueError(f"{label}：单一立体异构体须指定全部手性中心")
    if item["id"] in ENHANCED_CIS_IDS:
        groups = mol.GetStereoGroups()
        if len(groups) != 1 or groups[0].GetGroupType() != Chem.StereoGroupType.STEREO_AND:
            raise ValueError(f"{label}：须保留 cis 外消旋 AND 组")
        if len(groups[0].GetAtoms()) != 2:
            raise ValueError(f"{label}：AND 组须包含两个手性中心")
        if stereo_signature(mol) != stereo_signature(source):
            raise ValueError(f"{label}：增强立体组须与参考形态一致")
    bonds = [
        {
            "atoms": [bond.GetBeginAtomIdx(), bond.GetEndAtomIdx()],
            "configuration": bond.GetProp("_CIPCode"),
        }
        for bond in mol.GetBonds()
        if bond.GetBondType() == Chem.BondType.DOUBLE
        and bond.GetStereo() != Chem.BondStereo.STEREONONE
    ]
    if bonds != reference["doubleBondStereo"]:
        raise ValueError(f"{label}：双键立体记录须与来源一致")
    if len(Chem.GetMolFrags(mol)) != 1:
        raise ValueError(f"{label}：使用单一活性分子形态")
    return mol


def stereo_signature(mol: Chem.Mol) -> str:
    normalized = Chem.Mol(mol)
    Chem.CanonicalizeEnhancedStereo(normalized)
    return Chem.MolToCXSmiles(
        normalized, Chem.SmilesWriteParams(), Chem.CXSmilesFields.CX_ENHANCEDSTEREO
    )


def validate_live_sources(references: list[dict]) -> None:
    live = load_live_properties(references)
    for reference in references:
        current = live.get(reference["cid"])
        if current is None:
            raise ValueError(f"{reference['id']}：PubChem CID 查询结果缺失")
        if current.get("MolecularFormula") != reference["formula"]:
            raise ValueError(f"{reference['id']}：PubChem 分子式需同步")
        if current["Charge"] != reference["formalCharge"]:
            raise ValueError(f"{reference['id']}：PubChem 电荷需同步")
        if current["ConnectivitySMILES"] != reference["canonicalSmiles"]:
            raise ValueError(f"{reference['id']}：PubChem Canonical SMILES 需同步")
        source = Chem.MolFromSmiles(reference["referenceSmiles"])
        live_mol = Chem.MolFromSmiles(
            current.get("SMILES") or current.get("IsomericSMILES")
        )
        if source is None or live_mol is None:
            raise ValueError(f"{reference['id']}：PubChem 结构解析失败")
        if Chem.MolToSmiles(source, isomericSmiles=False) != Chem.MolToSmiles(
            live_mol, isomericSmiles=False
        ):
            raise ValueError(f"{reference['id']}：PubChem 连接关系需同步")
        if Chem.MolToSmiles(source, isomericSmiles=True) != Chem.MolToSmiles(
            live_mol, isomericSmiles=True
        ):
            raise ValueError(f"{reference['id']}：PubChem 立体表达需同步")


def validate_taxonomy_fields(item: dict, reference: dict) -> None:
    did = item["id"]
    if item["name"] != reference["name"]:
        raise ValueError(f"{did}：名称需与来源记录一致")
    if item["chapter"] not in STANDARD_CHAPTERS:
        raise ValueError(f"{did}：章节名称需使用标准章节")
    if reference["chapter"] != item["chapter"]:
        raise ValueError(f"{did}：来源章节须与题库一致")
    subcat = item.get("subcategory", "").strip()
    if not subcat or "其他" in subcat:
        raise ValueError(f"{did}：二级小类须为具体分类且不得包含“其他”")
    if reference.get("subcategory") != subcat:
        raise ValueError(f"{did}：来源记录二级小类须与题库一致")
    mech = item.get("mechanism", "").strip()
    if not mech or reference.get("mechanism") != mech:
        raise ValueError(f"{did}：作用靶点/机制须完整填写并与来源记录一致")
    if item["category"] != f"{item['chapter']} · {subcat}":
        raise ValueError(f"{did}：分类展示须与大类和小类一致")
    if item["structure"] != f"assets/structures/{did}.svg":
        raise ValueError(f"{did}：结构图资源路径需对应编号")
    if not item["aliases"] or not reference.get("verifiedSynonyms"):
        raise ValueError(f"{did}：别称与英文同义词来源记录须填写完整")


def validate_catalog(drugs: list[dict], *, check_live: bool = True) -> None:
    references = json.loads((ROOT / "tools/drug_reference.json").read_text(encoding="utf-8"))
    expected_ids = [f"{index:02}" for index in range(1, len(drugs) + 1)]
    if len(drugs) != EXPECTED_COUNT:
        raise ValueError(f"题库数量须为 {EXPECTED_COUNT}")
    if [item["id"] for item in drugs] != expected_ids:
        raise ValueError("题库编号须连续排列")
    if [item["id"] for item in references] != expected_ids:
        raise ValueError("来源记录须覆盖全部题库编号")
    if len({item["name"] for item in drugs}) != len(drugs):
        raise ValueError("药名须保持唯一")
    chapters = {item.get("chapter") for item in drugs}
    if not set(STANDARD_CHAPTERS).issubset(chapters):
        raise ValueError("24 个标准大类须全部覆盖")
    sort_orders = [item.get("sortOrder") for item in drugs]
    if sorted(sort_orders) != list(range(1, EXPECTED_COUNT + 1)):
        raise ValueError(f"sortOrder 须覆盖 1..{EXPECTED_COUNT} 且唯一")
    ordered_drugs = sorted(drugs, key=lambda d: d["sortOrder"])
    seen_groups: set[tuple[str, str]] = set()
    prev_group: tuple[str, str] | None = None
    for item in ordered_drugs:
        group = (item["chapter"], item["subcategory"])
        if group != prev_group:
            if group in seen_groups:
                raise ValueError(f"{group}：同小类药物顺序出现断层")
            seen_groups.add(group)
            prev_group = group
    conn_owners: dict[str, str] = {}
    iso_structures: set[str] = set()
    for item, reference in zip(drugs, references, strict=True):
        validate_taxonomy_fields(item, reference)
        mol = validate_drug(item, reference)
        iso_identity = canonical(mol, item["id"])
        if iso_identity in iso_structures:
            raise ValueError(f"{item['id']}：立体分子结构与已有条目重复")
        iso_structures.add(iso_identity)
        conn_identity = Chem.MolToSmiles(mol, isomericSmiles=False)
        prev_id = conn_owners.get(conn_identity)
        if prev_id is not None and frozenset({prev_id, item["id"]}) not in STEREOISOMER_CONN_PAIRS:
            raise ValueError(f"{item['id']}：分子连接与已有条目 {prev_id} 重复")
        conn_owners[conn_identity] = item["id"]
    if check_live:
        validate_live_sources(references)
    print(f"{len(drugs)} 项：编号、具体亚类、作用靶点机制、唯一性、来源结构、分子式、电荷与立体信息检查通过。")


if __name__ == "__main__":
    validate_catalog(json.loads((ROOT / "assets/drugs.json").read_text(encoding="utf-8")))
