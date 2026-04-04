#!/usr/bin/env python3
# Generates lib/data/regions_seed_generated.dart from structured admin data.
# Run: python tool/build_uz_regions_seed.py

from __future__ import annotations

import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "lib" / "data" / "regions_seed_generated.dart"

# (code, uz, ru, en)
REGIONS = [
    ("TK", "Toshkent shahri", "г. Ташкент", "Tashkent city"),
    ("TO", "Toshkent viloyati", "Ташкентская область", "Tashkent region"),
    ("AN", "Andijon viloyati", "Андижанская область", "Andijan region"),
    ("BU", "Buxoro viloyati", "Бухарская область", "Bukhara region"),
    ("FA", "Fargʻona viloyati", "Ферганская область", "Fergana region"),
    ("JI", "Jizzax viloyati", "Джизакская область", "Jizzakh region"),
    ("QA", "Qashqadaryo viloyati", "Кашкадарьинская область", "Kashkadarya region"),
    ("NA", "Navoiy viloyati", "Навоийская область", "Navoiy region"),
    ("NG", "Namangan viloyati", "Наманганская область", "Namangan region"),
    ("SA", "Samarqand viloyati", "Самаркандская область", "Samarkand region"),
    ("SU", "Surxondaryo viloyati", "Сурхандарьинская область", "Surkhandarya region"),
    ("SI", "Sirdaryo viloyati", "Сырдарьинская область", "Sirdarya region"),
    ("XO", "Xorazm viloyati", "Хорезмская область", "Khorezm region"),
    ("QR", "Qoraqalpogʻiston Respublikasi", "Республика Каракалпакстан", "Karakalpakstan"),
]

# (region_code, suffix, uz_label, ru, en) — uz_label: "… tumani" yoki "… shahri"
# code = region + "_" + suffix. TK_C va TK_Y eski bazadan keladi.
DISTRICTS: list[tuple[str, str, str, str, str]] = []


def add(region: str, suffix: str, uz: str, ru: str, en: str) -> None:
    DISTRICTS.append((region, suffix, f"{uz} tumani", ru, en))


def add_shahar(region: str, suffix: str, uz: str, ru: str, en: str) -> None:
    """Viloyat markazi yoki shahar maqomidagi aholi punkti (UI: … shahri)."""
    DISTRICTS.append((region, suffix, f"{uz} shahri", ru, en))


# --- Toshkent shahri (TK) ---
add("TK", "C", "Chilonzor", "Чиланзарский район", "Chilonzor district")
add("TK", "Y", "Yunusobod", "Юнусабадский район", "Yunusobod district")
add("TK", "BEK", "Bektemir", "Бектемирский район", "Bektemir district")
add("TK", "YAS", "Yashnobod", "Яшнабадский район", "Yashnobod district")
add("TK", "MIR", "Mirobod", "Мирабадский район", "Mirobod district")
add("TK", "MUZ", "Mirzo Ulugʻbek", "Мирзо-Улугбекский район", "Mirzo Ulugbek district")
add("TK", "SER", "Sergeli", "Сергелийский район", "Sergeli district")
add("TK", "SHA", "Shayxontohur", "Шайхантахурский район", "Shaykhantahur district")
add("TK", "OLM", "Olmazor", "Алмазарский район", "Olmazor district")
add("TK", "UCH", "Uchtepa", "Учтепинский район", "Uchtepa district")
add("TK", "YAK", "Yakkasaroy", "Яккасарайский район", "Yakkasaray district")
add("TK", "YAN", "Yangihayot", "Янгихаётский район", "Yangihayot district")

# --- Toshkent viloyati (TO) ---
for suffix, uz, ru, en in [
    ("BEK", "Bekobod", "Бекабадский район", "Bekabad district"),
    ("BOS", "Boʻstonliq", "Бостанлыкский район", "Bostanlyk district"),
    ("BOK", "Boʻka", "Букинский район", "Buka district"),
    ("CHN", "Chinoz", "Чиназский район", "Chinoz district"),
    ("QIB", "Qibray", "Кибрайский район", "Qibray district"),
    ("OHA", "Ohangaron", "Ахангаранский район", "Ohangaron district"),
    ("OQQ", "Oqqoʻrgʻon", "Аккурганский район", "Akkurgan district"),
    ("PAR", "Parkent", "Паркентский район", "Parkent district"),
    ("PIS", "Piskent", "Пскентский район", "Piskent district"),
    ("QCH", "Quyichirchiq", "Нижнечирчикский район", "Lower Chirchiq district"),
    ("ZAN", "Zangiota", "Зангиатинский район", "Zangiota district"),
    ("ORT", "Oʻrtachirchiq", "Среднечирчикский район", "Middle Chirchiq district"),
    ("YNG", "Yangiyoʻl", "Янгиюльский район", "Yangiyol district"),
    ("YUK", "Yuqorichirchiq", "Верхнечирчикский район", "Upper Chirchiq district"),
    ("TUM", "Toshkent", "Ташкентский район", "Tashkent district"),
]:
    add("TO", suffix, uz, ru, en)

# --- Qoraqalpogʻiston (QR) ---
for suffix, uz, ru, en in [
    ("AMU", "Amudaryo", "Амударьинский район", "Amudarya district"),
    ("BER", "Beruniy", "Берунийский район", "Beruniy district"),
    ("BOZ", "Boʻzatov", "Бузатауский район", "Bozatau district"),
    ("CHI", "Chimboy", "Чимбайский район", "Chimbay district"),
    ("ELL", "Ellikqalʼa", "Элликкалинский район", "Ellikkala district"),
    ("KEG", "Kegeyli", "Кегейлийский район", "Kegeyli district"),
    ("MOY", "Moʻynoq", "Муйнакский район", "Muynak district"),
    ("QAN", "Qanlikoʻl", "Канлыкульский район", "Kanlikul district"),
    ("QNG", "Qoʻngʻirot", "Кунградский район", "Kungrad district"),
    ("QOR", "Qoraoʻzak", "Караузякский район", "Karaozek district"),
    ("SHU", "Shumanay", "Шуманайский район", "Shumanay district"),
    ("TXT", "Taxtakoʻpir", "Тахтакупырский район", "Takhtakupir district"),
    ("TRT", "Toʻrtkoʻl", "Турткульский район", "Turtkul district"),
    ("XJA", "Xoʻjayli", "Ходжейлийский район", "Khodjeyli district"),
    ("TXA", "Taxiatosh", "Тахиаташский район", "Takhiatash district"),
]:
    add("QR", suffix, uz, ru, en)

add_shahar("QR", "NUK", "Nukus", "г. Нукус", "Nukus city")

# --- Xorazm (XO) ---
for suffix, uz, ru, en in [
    ("BOG", "Bogʻot", "Багатский район", "Bagat district"),
    ("GUR", "Gurlan", "Гурленский район", "Gurlan district"),
    ("XON", "Xonqa", "Ханкинский район", "Khonka district"),
    ("HAZ", "Hazorasp", "Хазараспский район", "Hazorasp district"),
    ("QSH", "Qoʻshkoʻpir", "Кушкупирский район", "Kushkupir district"),
    ("SHV", "Shovot", "Шаватский район", "Shavat district"),
    ("YAR", "Yangiariq", "Янгиарыкский район", "Yangiariq district"),
    ("YBO", "Yangibozor", "Янгибазарский район", "Yangibazar district"),
    ("TUP", "Tuproqqalʼa", "Тупраккалинский район", "Tuprakalla district"),
]:
    add("XO", suffix, uz, ru, en)

add_shahar("XO", "URG", "Urganch", "г. Ургенч", "Urgench city")
add_shahar("XO", "XIV", "Xiva", "г. Хива", "Khiva city")

# --- Navoiy (NA) ---
for suffix, uz, ru, en in [
    ("KON", "Konimex", "Канимехский район", "Konimex district"),
    ("QIZ", "Qiziltepa", "Кызылтепинский район", "Kyzyltepa district"),
    ("XAT", "Xatirchi", "Хатырчинский район", "Khatirchi district"),
    ("NVB", "Navbahor", "Навбахорский район", "Navbahor district"),
    ("KAR", "Karmana", "Карманинский район", "Karmana district"),
    ("NUR", "Nurota", "Нуратинский район", "Nurota district"),
    ("TOM", "Tomdi", "Тамдынский район", "Tamdy district"),
    ("UCH", "Uchquduq", "Учкудукский район", "Uchkuduk district"),
]:
    add("NA", suffix, uz, ru, en)

add_shahar("NA", "NVY", "Navoiy", "г. Навои", "Navoiy city")

# --- Buxoro (BU) ---
for suffix, uz, ru, en in [
    ("OLO", "Olot", "Алатский район", "Alat district"),
    ("GIJ", "Gʻijduvon", "Гиждуванский район", "Gijduvan district"),
    ("JON", "Jondor", "Жондорский район", "Jondor district"),
    ("KOG", "Kogon", "Каганский район", "Kagan district"),
    ("QKL", "Qorakoʻl", "Каракульский район", "Karakul district"),
    ("QVB", "Qorovulbozor", "Караулбазарский район", "Karaulbazar district"),
    ("PES", "Peshku", "Пешкунский район", "Peshku district"),
    ("ROM", "Romitan", "Ромитанский район", "Romitan district"),
    ("SHF", "Shofirkon", "Шафирканский район", "Shafirkan district"),
    ("VOB", "Vobkent", "Вабкентский район", "Vabkent district"),
]:
    add("BU", suffix, uz, ru, en)

add_shahar("BU", "BUX", "Buxoro", "г. Бухара", "Bukhara city")

# --- Samarqand (SA) ---
for suffix, uz, ru, en in [
    ("BUL", "Bulungʻur", "Булунгурский район", "Bulungur district"),
    ("ISH", "Ishtixon", "Иштыханский район", "Ishtikhon district"),
    ("JOM", "Jomboy", "Джамбайский район", "Jambay district"),
    ("QSR", "Qoʻshrabot", "Кушрабадский район", "Kushrabot district"),
    ("NAR", "Narpay", "Нарпайский район", "Narpay district"),
    ("NUB", "Nurobod", "Нурабадский район", "Nurabad district"),
    ("OQD", "Oqdaryo", "Акдарьинский район", "Akdarya district"),
    ("PXT", "Paxtachi", "Пахтачинский район", "Pakhtachi district"),
    ("PAY", "Payariq", "Пайарыкский район", "Payaryk district"),
    ("PST", "Pastdargʻom", "Пастдаргомский район", "Pastdargom district"),
    ("TOY", "Toyloq", "Тайлакский район", "Tailak district"),
    ("URG", "Urgut", "Ургутский район", "Urgut district"),
]:
    add("SA", suffix, uz, ru, en)

add_shahar("SA", "SAM", "Samarqand", "г. Самарканд", "Samarkand city")
add_shahar("SA", "KAT", "Kattaqoʻrgʻon", "г. Каттакурган", "Kattakurgan city")

# --- Qashqadaryo (QA) ---
for suffix, uz, ru, en in [
    ("CHI", "Chiroqchi", "Чиракчинский район", "Chirakchi district"),
    ("DEH", "Dehqonobod", "Дехканабадский район", "Dehkanabad district"),
    ("GUZ", "Gʻuzor", "Гузарский район", "Guzar district"),
    ("QAM", "Qamashi", "Камашинский район", "Kamashi district"),
    ("KOS", "Koson", "Касанский район", "Kasan district"),
    ("KAS", "Kasbi", "Касбинский район", "Kasbi district"),
    ("MIR", "Mirishkor", "Миришкорский район", "Mirishkor district"),
    ("MUB", "Muborak", "Мубарекский район", "Mubarek district"),
    ("NIS", "Nishon", "Нишанский район", "Nishon district"),
    ("YAK", "Yakkabogʻ", "Яккабагский район", "Yakkabag district"),
    ("KOK", "Koʻkdala", "Кукдалинский район", "Kokdala district"),
]:
    add("QA", suffix, uz, ru, en)

add_shahar("QA", "QAR", "Qarshi", "г. Карши", "Karshi city")
add_shahar("QA", "KIT", "Kitob", "г. Китаб", "Kitab city")
add_shahar("QA", "SHH", "Shahrisabz", "г. Шахрисабз", "Shakhrisabz city")

# --- Surxondaryo (SU) ---
for suffix, uz, ru, en in [
    ("ANG", "Angor", "Ангорский район", "Angor district"),
    ("BND", "Bandixon", "Бандихонский район", "Bandikhon district"),
    ("BOY", "Boysun", "Байсунский район", "Baysun district"),
    ("DEN", "Denov", "Денауский район", "Denau district"),
    ("JRQ", "Jarqoʻrgʻon", "Джаркурганский район", "Djarkurgan district"),
    ("QZI", "Qiziriq", "Кизирикский район", "Kizirik district"),
    ("QMQ", "Qumqoʻrgʻon", "Кумкурганский район", "Kumkurgan district"),
    ("MUZ", "Muzrabot", "Музрабадский район", "Muzrabot district"),
    ("OLT", "Oltinsoy", "Алтынсайский район", "Altinsay district"),
    ("SAR", "Sariosiyo", "Сариасийский район", "Sariasiya district"),
    ("SHE", "Sherobod", "Шерабадский район", "Sherabad district"),
    ("SHR", "Shoʻrchi", "Шурчинский район", "Shurchi district"),
    ("UZU", "Uzun", "Узунский район", "Uzun district"),
]:
    add("SU", suffix, uz, ru, en)

add_shahar("SU", "TER", "Termiz", "г. Термез", "Termez city")

# --- Jizzax (JI) ---
for suffix, uz, ru, en in [
    ("ARN", "Arnasoy", "Арнасайский район", "Arnasay district"),
    ("BAX", "Baxmal", "Бахмальский район", "Bakhmal district"),
    ("DOS", "Doʻstlik", "Дустликский район", "Dustlik district"),
    ("FOR", "Forish", "Фаришский район", "Farish district"),
    ("GAL", "Gʻallaorol", "Галляаральский район", "Gallaaral district"),
    ("SHR", "Sharof Rashidov", "им. Ш. Рашидова", "Sharof Rashidov district"),
    ("MRZ", "Mirzachoʻl", "Мирзачульский район", "Mirzachul district"),
    ("PAX", "Paxtakor", "Пахтакорский район", "Pakhtakor district"),
    ("YOB", "Yangiobod", "Янгиабадский район", "Yangiobod district"),
    ("ZOM", "Zomin", "Зааминский район", "Zaamin district"),
    ("ZFB", "Zafarobod", "Зафарабадский район", "Zafarabad district"),
    ("ZBD", "Zarbdor", "Зарбдарский район", "Zarbador district"),
]:
    add("JI", suffix, uz, ru, en)

add_shahar("JI", "JZX", "Jizzax", "г. Джизак", "Jizzakh city")

# --- Sirdaryo (SI) ---
for suffix, uz, ru, en in [
    ("OQO", "Oqoltin", "Акалтынский район", "Akaltyn district"),
    ("BOY", "Boyovut", "Баяутский район", "Bayaut district"),
    ("XOV", "Xovos", "Хавастский район", "Khavast district"),
    ("MRZ", "Mirzaobod", "Мирзаабадский район", "Mirzaabad district"),
    ("SAR", "Sardoba", "Сардобский район", "Sardoba district"),
    ("SAY", "Sayxunobod", "Сайхунабадский район", "Saykhunabad district"),
    ("SIR", "Sirdaryo", "Сырдарьинский район", "Sirdarya district"),
]:
    add("SI", suffix, uz, ru, en)

add_shahar("SI", "GUL", "Guliston", "г. Гулистан", "Guliston city")

# --- Namangan (NG) ---
for suffix, uz, ru, en in [
    ("CHO", "Chortoq", "Чартакский район", "Chartak district"),
    ("CHS", "Chust", "Чустский район", "Chust district"),
    ("KOS", "Kosonsoy", "Касансайский район", "Kasansay district"),
    ("MIN", "Mingbuloq", "Мингбулакский район", "Mingbulak district"),
    ("NOR", "Norin", "Норинский район", "Norin district"),
    ("POP", "Pop", "Папский район", "Pop district"),
    ("TRQ", "Toʻraqoʻrgʻon", "Туракурганский район", "Turakurgan district"),
    ("UCQ", "Uchqoʻrgʻon", "Учкурганский район", "Uchkurgan district"),
    ("UYC", "Uychi", "Уйчинский район", "Uychi district"),
    ("YNQ", "Yangiqoʻrgʻon", "Янгикурганский район", "Yangikurgan district"),
]:
    add("NG", suffix, uz, ru, en)

add_shahar("NG", "NAM", "Namangan", "г. Наманган", "Namangan city")

# --- Fargʻona (FA) ---
for suffix, uz, ru, en in [
    ("OLT", "Oltiariq", "Алтыарыкский район", "Altyaryk district"),
    ("BAG", "Bagʻdod", "Багдадский район", "Baghdad district"),
    ("BES", "Beshariq", "Бешарыкский район", "Besharyk district"),
    ("BUV", "Buvayda", "Бувадайский район", "Buvaida district"),
    ("DAN", "Dangʻara", "Дангараский район", "Dangara district"),
    ("FUR", "Furqat", "Фуркатский район", "Furkat district"),
    ("QST", "Qoʻshtepa", "Куштепинский район", "Kushtepa district"),
    ("QUV", "Quva", "Кувинский район", "Kuva district"),
    ("RIS", "Rishton", "Риштанский район", "Rishtan district"),
    ("SOX", "Soʻx", "Сохский район", "Sokh district"),
    ("TOS", "Toshloq", "Ташлакский район", "Tashlak district"),
    ("UCP", "Uchkoʻprik", "Учкуприкский район", "Uchkuprik district"),
    ("UZB", "Oʻzbekiston", "Узбекистанский район", "Uzbekistan district"),
    ("YOZ", "Yozyovon", "Язъяванский район", "Yazyovan district"),
]:
    add("FA", suffix, uz, ru, en)

add_shahar("FA", "FER", "Fargʻona", "г. Фергана", "Fergana city")
add_shahar("FA", "MRG", "Margʻilon", "г. Маргилан", "Margilan city")

# --- Andijon (AN) ---
for suffix, uz, ru, en in [
    ("ASA", "Asaka", "Асакинский район", "Asaka district"),
    ("BAL", "Baliqchi", "Балыкчинский район", "Balykchi district"),
    ("BST", "Boʻston", "Бустонский район", "Buston district"),
    ("BLQ", "Buloqboshi", "Булакбашинский район", "Bulakbashi district"),
    ("IZB", "Izboskan", "Избасканский район", "Izboskan district"),
    ("JAL", "Jalaquduq", "Джалакудукский район", "Dzhalakuduk district"),
    ("XJA", "Xoʻjaobod", "Ходжаабадский район", "Khodjaabad district"),
    ("QGT", "Qoʻrgʻontepa", "Кургантепинский район", "Kurgantepa district"),
    ("MRH", "Marhamat", "Мархаматский район", "Marhamat district"),
    ("OLK", "Oltinkoʻl", "Алтынкульский район", "Altynkul district"),
    ("PAX", "Paxtaobod", "Пахтаабадский район", "Pakhtaabad district"),
    ("SHX", "Shahrixon", "Шахриханский район", "Shakhrikhan district"),
    ("ULN", "Ulugʻnor", "Улугнарский район", "Ulugnor district"),
]:
    add("AN", suffix, uz, ru, en)

add_shahar("AN", "AND", "Andijon", "г. Андижан", "Andijan city")


def main() -> None:
    data = {
        "regions": [
            {"code": c, "uz": uz, "ru": ru, "en": en} for c, uz, ru, en in REGIONS
        ],
        "districts": [
            {
                "code": f"{reg}_{suf}",
                "regionCode": reg,
                "uz": uz_disp,
                "ru": ru,
                "en": en,
            }
            for reg, suf, uz_disp, ru, en in DISTRICTS
        ],
    }
    raw = json.dumps(data, ensure_ascii=False)
    # Dart raw string: escape only triple quotes if any
    safe = raw.replace(r"'''", r"'\''\''\''")
    dart = f"""// GENERATED BY tool/build_uz_regions_seed.py — do not edit by hand.
// ignore_for_file: lines_longer_than_80_chars

import 'dart:convert';

import '../models/localized_string.dart';
import '../models/region_record.dart';

abstract final class RegionsSeedGenerated {{
  static final String _json = r'{safe}';

  static List<RegionRecord> parseRegions() {{
    final map = jsonDecode(_json) as Map<String, dynamic>;
    final list = map['regions'] as List<dynamic>;
    return list
        .map(
          (e) => RegionRecord(
            code: e['code'] as String,
            name: LocalizedString(
              uz: e['uz'] as String,
              ru: e['ru'] as String,
              en: e['en'] as String,
            ),
          ),
        )
        .toList();
  }}

  static List<DistrictRecord> parseDistricts() {{
    final map = jsonDecode(_json) as Map<String, dynamic>;
    final list = map['districts'] as List<dynamic>;
    return list
        .map(
          (e) => DistrictRecord(
            code: e['code'] as String,
            regionCode: e['regionCode'] as String,
            name: LocalizedString(
              uz: e['uz'] as String,
              ru: e['ru'] as String,
              en: e['en'] as String,
            ),
          ),
        )
        .toList();
  }}
}}
"""
    OUT.write_text(dart, encoding="utf-8")
    print(f"Wrote {OUT} ({len(DISTRICTS)} districts)")


if __name__ == "__main__":
    main()
