"""生成 232 项药物的 0°、90°、180°、270° 透明 SVG 结构图。"""

from __future__ import annotations

import json
import math
import re
from pathlib import Path

from rdkit import Chem
from rdkit.Chem import rdDepictor
from rdkit.Chem.Draw import rdMolDraw2D

from drug_validation import CISPLATIN_ID, ENHANCED_CIS_IDS, stereo_signature, validate_catalog

PROJECT_ROOT = Path(__file__).resolve().parent.parent
DRUGS_JSON = PROJECT_ROOT / "assets" / "drugs.json"
CANVAS_WIDTH = 480
CANVAS_HEIGHT = 280
SAFE_MARGIN = 8.0
INK_COLOR = (0.09, 0.13, 0.19, 1.0)
ANGLES = (0, 90, 180, 270)

STEROID_REF_SMILES = (
    "C[C@]12CCC(=O)C=C1CC[C@@H]3[C@@H]2[C@@H](O)C[C@@]4(C)[C@H]3CC[C@]4(O)C(=O)CO"
)
STEROID_CORE_SMARTS = (
    "[#6]1~[#6]~[#6]~[#6]2~[#6](~[#6]~1)~[#6]~[#6]~[#6]3"
    "~[#6]~2~[#6]~[#6]~[#6]4~[#6]~[#6]~[#6]~[#6]~3~4"
)
QUINOLONE_REF_SMILES = "CCn1cc(C(=O)O)c(=O)c2cc(F)c(N3CCNCC3)cc21"
QUINOLONE_CORE_SMARTS = "O=c1c(C(=O)O)cn([#6])c2ccccc12"


def build_template(ref_smiles: str, core_smarts: str) -> Chem.Mol:
    """从参考分子提取带标准 2D 坐标的子结构模板。"""
    ref = Chem.MolFromSmiles(ref_smiles)
    rdDepictor.SetPreferCoordGen(True)
    rdDepictor.Compute2DCoords(ref)
    core = Chem.MolFromSmarts(core_smarts)
    match = ref.GetSubstructMatch(core)
    if not match:
        raise ValueError(f"参考分子未匹配模板: {core_smarts}")
    source_conf = ref.GetConformer()
    core_conf = Chem.Conformer(core.GetNumAtoms())
    for core_idx, ref_idx in enumerate(match):
        core_conf.SetAtomPosition(core_idx, source_conf.GetAtomPosition(ref_idx))
    core.AddConformer(core_conf, assignId=True)
    return core


def assign_cisplatin_coords(mol: Chem.Mol) -> None:
    """为顺铂分配标准平面正方形顺式（cis）2D 几何坐标。"""
    mol.RemoveAllConformers()
    conf = Chem.Conformer(mol.GetNumAtoms())
    # [NH3]->[Pt@SP3](<-[NH3])([Cl])[Cl]：0=N, 1=Pt, 2=N, 3=Cl, 4=Cl
    conf.SetAtomPosition(1, (0.0, 0.0, 0.0))
    conf.SetAtomPosition(0, (-1.1, 0.85, 0.0))
    conf.SetAtomPosition(2, (-1.1, -0.85, 0.0))
    conf.SetAtomPosition(3, (1.1, 0.85, 0.0))
    conf.SetAtomPosition(4, (1.1, -0.85, 0.0))
    mol.AddConformer(conf, assignId=True)


def compute_coords(drug_id: str, mol: Chem.Mol, templates: dict[str, Chem.Mol]) -> None:
    """计算 2D 坐标并按需对齐母核模板。"""
    if drug_id == CISPLATIN_ID:
        assign_cisplatin_coords(mol)
        return
    rdDepictor.SetPreferCoordGen(True)
    if drug_id in {"08", "53"}:
        rdDepictor.Compute2DCoords(mol, forceRDKit=True)
        return
    template_key = next(
        (key for key, template in templates.items() if mol.HasSubstructMatch(template)),
        None,
    )
    if template_key is None:
        rdDepictor.Compute2DCoords(mol)
        if drug_id in {"61", "77", "88", "92"}:
            rdDepictor.NormalizeDepiction(mol, canonicalize=1)
        return
    rdDepictor.Compute2DCoords(mol)
    params = rdDepictor.ConstrainedDepictionParams()
    params.alignOnly = True
    rdDepictor.GenerateDepictionMatching2DStructure(
        mol, templates[template_key], params=params
    )


def clear_stereo_bond_directions(mol: Chem.Mol) -> None:
    for bond in mol.GetBonds():
        if bond.GetBondDir() in {Chem.BondDir.BEGINWEDGE, Chem.BondDir.BEGINDASH}:
            bond.SetBondDir(Chem.BondDir.NONE)


def prepare_base(drug_id: str, smiles: str, templates: dict[str, Chem.Mol]) -> Chem.Mol:
    """生成 0° 基准坐标，并由最终坐标重新分配立体键。"""
    mol = Chem.MolFromSmiles(smiles)
    if mol is None:
        raise ValueError(f"SMILES 解析失败: {drug_id}")
    if drug_id == CISPLATIN_ID:
        assign_cisplatin_coords(mol)
        return rdMolDraw2D.PrepareMolForDrawing(mol, kekulize=True)
    prepared = rdMolDraw2D.PrepareMolForDrawing(mol, kekulize=False)
    compute_coords(drug_id, prepared, templates)
    clear_stereo_bond_directions(prepared)
    return rdMolDraw2D.PrepareMolForDrawing(prepared, kekulize=True)


def rotate_mol(base: Chem.Mol, angle: int) -> Chem.Mol:
    """围绕 2D 包围盒中心施加纯二维刚体旋转。"""
    rotated = Chem.Mol(base)
    conformer = rotated.GetConformer()
    positions = [conformer.GetAtomPosition(index) for index in range(rotated.GetNumAtoms())]
    center_x = (min(point.x for point in positions) + max(point.x for point in positions)) / 2
    center_y = (min(point.y for point in positions) + max(point.y for point in positions)) / 2
    radians = math.radians(angle)
    cosine = math.cos(radians)
    sine = math.sin(radians)
    for index, point in enumerate(positions):
        dx = point.x - center_x
        dy = point.y - center_y
        x = center_x + cosine * dx - sine * dy
        y = center_y + sine * dx + cosine * dy
        conformer.SetAtomPosition(index, (x, y, point.z))
    clear_stereo_bond_directions(rotated)
    return rdMolDraw2D.PrepareMolForDrawing(rotated, kekulize=True)


def validate_round_trip(mol: Chem.Mol, source: Chem.Mol, drug_id: str, angle: int) -> None:
    """回读 MolBlock，确认异构 SMILES 与增强立体组保持一致。"""
    restored = Chem.MolFromMolBlock(Chem.MolToMolBlock(mol))
    if restored is None:
        raise ValueError(f"{drug_id} {angle}°：MolBlock 回读失败")
    if Chem.MolToSmiles(restored, isomericSmiles=True) != Chem.MolToSmiles(
        source, isomericSmiles=True
    ):
        raise ValueError(f"{drug_id} {angle}°：异构 SMILES 往返结果需一致")
    if stereo_signature(restored) != stereo_signature(source):
        raise ValueError(f"{drug_id} {angle}°：增强立体组往返结果需一致")


def svg_coord_points(svg_text: str) -> list[tuple[float, float]]:
    """读取 SVG 图元坐标点，用于横纵坐标范围校验。"""
    points: list[tuple[float, float]] = []
    for path_data in re.findall(r" d='([^']+)'", svg_text):
        tokens = re.findall(
            r"[MLCQZmlcqz]|[-+]?(?:\d+\.\d*|\.\d+|\d+)", path_data
        )
        cursor = 0
        command = ""
        current = (0.0, 0.0)
        while cursor < len(tokens):
            if tokens[cursor].isalpha():
                command = tokens[cursor]
                cursor += 1
            if command.upper() == "Z":
                continue
            size = {"M": 2, "L": 2, "C": 6, "Q": 4}.get(command.upper(), 0)
            if size == 0 or cursor + size > len(tokens):
                break
            numbers = [float(value) for value in tokens[cursor : cursor + size]]
            cursor += size
            relative = command.islower()
            for index in range(0, len(numbers), 2):
                x, y = numbers[index], numbers[index + 1]
                if relative:
                    x += current[0]
                    y += current[1]
                points.append((x, y))
                current = (x, y)
            if command.upper() == "M":
                command = "l" if relative else "L"
    for x, y in re.findall(r"\bx='([^']+)'\s+y='([^']+)'", svg_text):
        points.append((float(x), float(y)))
    return points


def validate_svg(svg_text: str, drug_id: str, angle: int) -> None:
    """校验画布尺寸、透明背景和图元安全留白。"""
    if "width='480px'" not in svg_text or "height='280px'" not in svg_text:
        raise ValueError(f"{drug_id} {angle}°：SVG 画布需为 480×280")
    if "<rect" in svg_text or "fill=\"white\"" in svg_text:
        raise ValueError(f"{drug_id} {angle}°：背景需保持透明")
    points = svg_coord_points(svg_text)
    if not points:
        raise ValueError(f"{drug_id} {angle}°：SVG 图元坐标缺失")
    xs = [point[0] for point in points]
    ys = [point[1] for point in points]
    if (
        min(xs) < SAFE_MARGIN
        or max(xs) > CANVAS_WIDTH - SAFE_MARGIN
        or min(ys) < SAFE_MARGIN
        or max(ys) > CANVAS_HEIGHT - SAFE_MARGIN
    ):
        raise ValueError(f"{drug_id} {angle}°：图元需保留安全留白")


def render_svg(mol: Chem.Mol, source: Chem.Mol, drug_id: str, angle: int) -> str:
    """渲染单张透明背景、深炭墨色 SVG。"""
    validate_round_trip(mol, source, drug_id, angle)
    drawer = rdMolDraw2D.MolDraw2DSVG(CANVAS_WIDTH, CANVAS_HEIGHT)
    options = drawer.drawOptions()
    options.useBWAtomPalette()
    options.setAtomPalette({atomic_num: INK_COLOR for atomic_num in range(120)})
    options.setBackgroundColour((1.0, 1.0, 1.0, 0.0))
    options.clearBackground = False
    options.bondLineWidth = 2.0
    options.padding = 0.12
    options.minFontSize = 15
    options.maxFontSize = 22
    options.fixedBondLength = 0.0
    options.additionalAtomLabelPadding = 0.12
    if drug_id in ENHANCED_CIS_IDS:
        options.addStereoAnnotation = True
    drawer.DrawMolecule(mol)
    drawer.FinishDrawing()
    svg_text = drawer.GetDrawingText()
    validate_svg(svg_text, drug_id, angle)
    return svg_text


def output_path(item: dict, angle: int) -> Path:
    if angle == 0:
        return PROJECT_ROOT / item["structure"]
    return PROJECT_ROOT / "assets" / "structures" / f"rot{angle}" / f"{item['id']}.svg"


def main() -> None:
    templates = {
        "steroid": build_template(STEROID_REF_SMILES, STEROID_CORE_SMARTS),
        "quinolone": build_template(QUINOLONE_REF_SMILES, QUINOLONE_CORE_SMARTS),
    }
    drugs = json.loads(DRUGS_JSON.read_text(encoding="utf-8"))
    validate_catalog(drugs)
    generated = 0
    for item in drugs:
        source = Chem.MolFromSmiles(item["smiles"])
        base = prepare_base(item["id"], item["smiles"], templates)
        for angle in ANGLES:
            rotated = rotate_mol(base, angle)
            path = output_path(item, angle)
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(render_svg(rotated, source, item["id"], angle), encoding="utf-8")
            generated += 1
    print(f"{len(drugs)} 项数据校验通过，已生成 {generated} 张 480×280 透明 SVG。")


if __name__ == "__main__":
    main()
