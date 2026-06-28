use either::Right;
use esl::{Field, BodyPartKind, BodyPartType, NAME, BODY, BYDT, MODL, CodePage};
use esl::{Record, TES3, HEDR, RecordFlags, FileMetadata, FileType, StringZ, FNAM};
use esl::{BodyPart, BodyPartFlags, ARMO, AODT, Armor, ArmorType, ITEX, INDX, BipedObject};
use esl::{BNAM, MISC, MCDT, MiscItem, RecordSerde};
use esl::code::{self};
use esl::read::{Records, RecordReadMode};
use serde_serialize_seed::{ValueWithSeed, VecSerde};
use std::collections::HashMap;
use std::env::{self};
use std::fs::{self, File};
use std::io::{BufReader, BufRead, BufWriter};
use std::path::{Path, PathBuf};

struct OpenmwCfg {
    data: Vec<String>,
    content: Vec<String>,
}

fn unscreen_openmw_cfg_value(value: &str) -> String {
    if !value.starts_with('"') || !value.ends_with('"') { return value.to_string(); }
    let value = &value[1 .. value.len() - 1];
    let mut res = String::with_capacity(value.len());
    let mut amp = false;
    for c in value.chars() {
        if amp {
            amp = false;
            res.push(c);
        } else if c == '&' {
            amp = true;
        } else {
            res.push(c);
        }
    }
    res
}

fn parse_openmw_cfg(path: &Path) -> Option<OpenmwCfg> {
    let mut res = OpenmwCfg {
        data: Vec::new(),
        content: Vec::new(),
    };
    let file = match File::open(path) {
        Ok(file) => file,
        Err(e) => { eprintln!("Cannot open openmw.cfg: {e}"); return None; },
    };
    let reader = BufReader::new(file);
    for line in reader.lines() {
        let line = match line {
            Ok(line) => line,
            Err(e) => { eprintln!("Cannot read openmw.cfg: {e}"); return None; },
        };
        let line = line.trim();
        let Some(eq_pos) = line.find('=') else { continue; };
        let key = &line[.. eq_pos];
        let value = &line[eq_pos + 1 ..];
        let value = unscreen_openmw_cfg_value(value);
        match key {
            "data" => res.data.push(value),
            "content" => res.content.push(value),
            _ => { },
        }
    }
    Some(res)
}

fn find_openmw_cfg() -> Option<PathBuf> {
    let exe = match env::current_exe() {
        Ok(exe) => exe,
        Err(e) => { eprintln!("Cannot find executable path: {e}"); return None; },
    };
    let exe_dir = match exe.parent() {
        Some(exe_dir) => exe_dir,
        None => { eprintln!("Cannot find executable dir"); return None; },
    };
    Some(exe_dir.join("openmw.cfg"))
}

fn collect_heads_and_hairs(
    path: &Path,
    heads: &mut HashMap<String, String>,
    hairs: &mut HashMap<String, String>,
) {
    let mut file = match File::open(path) {
        Ok(file) => file,
        Err(e) => { eprintln!("Cannot open {}: {e}", path.display()); return; },
    };
    let records = Records::new(CodePage::Russian, RecordReadMode::Lenient, false, 0, &mut file);
    for record in records {
        let record = match record {
            Ok(record) => record,
            Err(e) => { eprintln!("Invalid file {}: {e}", path.display()); return; },
        };
        if record.tag != BODY { continue; }
        let Some(name_field) = record.fields.iter().find(|(tag, _)| *tag == NAME) else {
            eprintln!("Missing NAME field in {}", path.display());
            continue;
        };
        let Some(bydt_field) = record.fields.iter().find(|(tag, _)| *tag == BYDT) else {
            eprintln!("Missing BYDT field in {}", path.display());
            continue;
        };
        let Some(modl_field) = record.fields.iter().find(|(tag, _)| *tag == MODL) else {
            eprintln!("Missing MODL field in {}", path.display());
            continue;
        };
        let Field::BodyPart(part) = &bydt_field.1 else { panic!() };
        if part.body_part_type != BodyPartType::Skin { continue; }
        let Field::StringZ(id) = &name_field.1 else { panic!() };
        let id = id.string.to_lowercase();
        let Field::StringZ(model) = &modl_field.1 else { panic!() };
        let model = model.string.clone();
        match part.kind {
            BodyPartKind::Head => { heads.insert(id, model); },
            BodyPartKind::Hair => { hairs.insert(id, model); },
            _ => { },
        }
    }
}

fn id_hash(id: &str) -> u32 {
    let mut res = 5381u32;
    for b in id.bytes() {
        res = (res << 5).wrapping_add(res).wrapping_add(b.into());
    }
    res % 100000000
}

fn write_esp(
    path: &Path,
    heads: &HashMap<String, String>,
    hairs: &HashMap<String, String>,
) {
    let mut records = Vec::new();
    records.push(Record {
        tag: TES3,
        flags: RecordFlags::empty(),
        fields: vec![
            (HEDR, Field::FileMetadata(FileMetadata {
                version: 1067869798,
                file_type: FileType::ESP,
                author: Right("potions_balance".to_string()),
                description: Right(vec!["Potions balance.".into()]),
                records:
                    u32::try_from(hairs.len()).unwrap_or(u32::MAX)
                        .saturating_mul(2)
                        .saturating_add(u32::try_from(heads.len()).unwrap_or(u32::MAX)),
            }))
        ],
    });
    for (hair_id, hair_model) in hairs {
        let hash = id_hash(hair_id);
        let body_record = Record {
            tag: BODY,
            flags: RecordFlags::empty(),
            fields: vec![
                (NAME, Field::StringZ(StringZ { string: format!("A1_NecroB{hash}"), has_tail_zero: true })),
                (MODL, Field::StringZ(StringZ { string: hair_model.clone(), has_tail_zero: true })),
                (FNAM, Field::StringZ(StringZ { string: "Breton".to_string(), has_tail_zero: true })),
                (BYDT, Field::BodyPart(BodyPart {
                    kind: BodyPartKind::Hair,
                    vampire: false,
                    flags: BodyPartFlags::empty(),
                    body_part_type: BodyPartType::Armor,
                })),
            ],
        };
        records.push(body_record);
    }
    for (hair_id, hair_model) in hairs {
        let hash = id_hash(hair_id);
        let armo_record = Record {
            tag: ARMO,
            flags: RecordFlags::empty(),
            fields: vec![
                (NAME, Field::StringZ(StringZ { string: format!("A1_NecroH{hash}"), has_tail_zero: true })),
                (MODL, Field::StringZ(StringZ { string: hair_model.clone(), has_tail_zero: true })),
                (FNAM, Field::StringZ(StringZ { string: "Скальп".to_string(), has_tail_zero: true })),
                (AODT, Field::Armor(Armor {
                    armor_type: ArmorType::Helmet,
                    weight: 0.2,
                    value: 0,
                    health: 100,
                    enchantment: 0,
                    armor: 10,
                })),
                (ITEX, Field::StringZ(StringZ {
                    string: "a\\TX_Chitin_pauldron.tga".to_string(), has_tail_zero: true
                })),
                (INDX, Field::BipedObject(BipedObject::Hair)),
                (BNAM, Field::String(format!("A1_NecroB{hash}"))),
            ],
        };
        records.push(armo_record);
    }
    for (head_id, head_model) in heads {
        let hash = id_hash(head_id);
        let misc_record = Record {
            tag: MISC,
            flags: RecordFlags::empty(),
            fields: vec![
                (NAME, Field::StringZ(StringZ { string: format!("A1_NecroH{hash}"), has_tail_zero: true })),
                (MODL, Field::StringZ(StringZ { string: head_model.clone(), has_tail_zero: true })),
                (FNAM, Field::StringZ(StringZ { string: "Голова".to_string(), has_tail_zero: true })),
                (MCDT, Field::MiscItem(MiscItem {
                    weight: 1.0,
                    value: 0,
                    is_key: false,
                })),
                (ITEX, Field::StringZ(StringZ {
                    string: "m\\Misc_Com_Basket_01.tga".to_string(), has_tail_zero: true
                })),
            ],
        };
        records.push(misc_record);
    }
    {
        let file = match File::create(path) {
            Ok(file) => file,
            Err(e) => { eprintln!("Cannot create {}: {e}", path.display()); return; },
        };
        let mut writer = BufWriter::new(file);
        if
            let Err(e) = code::serialize_into(&ValueWithSeed(
                &records[..],
                VecSerde(RecordSerde { code_page: Some(CodePage::Russian), omwsave: false })
            ), &mut writer, true)
        {
            eprintln!("Cannot write {}: {e}", path.display());
            return;
        }
    }
}

fn main() {
    let Some(openmw_cfg_path) = find_openmw_cfg() else { return; };
    let Some(openmw_cfg) = parse_openmw_cfg(&openmw_cfg_path) else { return; };
    let mut heads = HashMap::new();
    let mut hairs = HashMap::new();
    for file_name in openmw_cfg.content {
        let file_name_uppercase = file_name.to_uppercase();
        if
               !file_name_uppercase.ends_with(".ESM")
            && !file_name_uppercase.ends_with(".ESP")
        {
            continue;
        }
        let Some(path) = openmw_cfg.data.iter().rev()
            .map(|x| {
                let mut path = PathBuf::from(x);
                path.push(&file_name);
                path
            })
            .find(|x| fs::metadata(x).ok().map_or(false, |x| x.is_file()))
        else {
            eprintln!("{file_name} not found");
            continue;
        };
        collect_heads_and_hairs(&path, &mut heads, &mut hairs);
    }
    if heads.is_empty() && hairs.is_empty() {
        eprintln!("Heads not found");
        return;
    }
    let mut esp_path = PathBuf::from(openmw_cfg.data.last().unwrap());
    esp_path.push("A1_Necromancy_Heads.esp");
    write_esp(&esp_path, &heads, &hairs);
}
