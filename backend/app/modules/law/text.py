"""Deterministic French presentation text; original titles are kept separately."""

import html
import re
import unicodedata
from html.parser import HTMLParser
from urllib.parse import urlsplit, urlunsplit


class _PlainText(HTMLParser):
    def __init__(self) -> None:
        super().__init__(convert_charrefs=True)
        self.parts: list[str] = []
        self.hidden = 0

    def handle_starttag(self, tag: str, attrs: list) -> None:
        if tag in {"script", "style"}:
            self.hidden += 1
        if tag in {"p", "div", "br", "li"}:
            self.parts.append("\n")

    def handle_endtag(self, tag: str) -> None:
        if tag in {"script", "style"}:
            self.hidden = max(0, self.hidden - 1)
        if tag in {"p", "div", "li"}:
            self.parts.append("\n")

    def handle_data(self, data: str) -> None:
        if not self.hidden:
            self.parts.append(data)


def plain_text(value: str | None) -> str:
    parser = _PlainText()
    parser.feed(html.unescape(html.unescape(value or "")))
    text = html.unescape(html.unescape("".join(parser.parts))).replace("\xa0", " ")
    text = re.split(r"(?i)\blien de suivi\s*:", text)[0]
    return "\n\n".join(
        re.sub(r"\s+", " ", line).strip() for line in text.splitlines() if line.strip()
    )


def canonical_url(url: str) -> str:
    parts = urlsplit(url.strip())
    return urlunsplit(("https", parts.netloc.lower(), parts.path.rstrip("/"), "", ""))


def subject_title(raw: str) -> str:
    text = re.sub(r"\s+", " ", plain_text(raw)).strip(" .?")
    text = text.replace("’", "'")
    text = re.sub(r"(?i)^êtes-vous favorable (?:à|au|aux)\s+", "", text)
    text = re.sub(r"(?i)^l'ensemble (?:du|de la)\s+", "", text)
    text = re.sub(r"(?i)^(?:projet|proposition) de loi\s*(?:organique\s*)?", "", text)
    text = re.sub(r"(?i)^loi du \d{1,2}(?:er)? \w+ \d{4}\s*", "", text)
    text = re.split(
        r"(?i)\s*\((?:texte|première lecture|deuxième lecture|nouvelle lecture|lecture définitive|procédure accélérée|lecture unique)\b",
        text,
    )[0]
    text = re.sub(
        r"(?i),?\s+en (?:première|deuxième|nouvelle|dernière) lecture.*$", "", text
    )
    return text.strip(" .?")


def clean_law_title(raw_title: str) -> str:
    """Form a grammatical question without changing the action or its qualifiers.

    Complex verbs are kept verbatim instead of unsafe partial nominalization.
    Unknown forms use a quoted title, keeping the algorithm conservative.
    """
    raw = re.sub(r"\s+", " ", plain_text(raw_title)).strip()
    if re.match(r"(?i)^êtes-vous favorable\b", raw):
        tail = re.sub(r"(?i)^êtes-vous favorable\s*", "", raw).rstrip(" .?")
        return f"Êtes-vous favorable {tail} ?"
    subject = subject_title(raw)
    if not subject:
        return "Êtes-vous favorable à ce texte ?"
    relative = re.match(
        r"(?i)^(?:organique )?relati(?:f|ve|fs|ves) (à|au|aux)\s+(.+)$", subject
    )
    if relative:
        preposition, complement = relative.groups()
        return f"Êtes-vous favorable {preposition.lower()} {complement} ?"
    if re.match(r"(?i)^(?:visant|tendant) à\b", subject):
        return f"Êtes-vous favorable à une loi {subject[0].lower() + subject[1:]} ?"
    infinitives = (
        "rendre",
        "protéger",
        "garantir",
        "réformer",
        "renforcer",
        "améliorer",
        "instaurer",
        "faciliter",
        "interdire",
        "réguler",
        "encadrer",
        "revaloriser",
        "conforter",
        "réparer",
        "réserver",
        "reconnaître",
        "moderniser",
        "exercer",
        "pérenniser",
        "étendre",
        "créer",
        "limiter",
        "adapter",
        "favoriser",
        "promouvoir",
        "assurer",
        "offrir",
        "supprimer",
        "sanctionner",
        "dépénaliser",
        "légaliser",
        "autoriser",
        "simplifier",
        "accélérer",
        "financer",
        "soutenir",
        "développer",
        "orienter",
        "programmer",
        "abroger",
        "rétablir",
        "actualiser",
        "allonger",
        "réduire",
        "augmenter",
        "lutter",
    )
    if re.match(r"(?i)^(?:mieux )?(?:" + "|".join(infinitives) + r")\b", subject):
        return f"Êtes-vous favorable à une loi visant à {subject[0].lower() + subject[1:]} ?"
    if re.match(r"(?i)^loi\s+", subject):
        return f"Êtes-vous favorable à une {subject[0].lower() + subject[1:]} ?"
    on = re.match(r"(?i)^portant sur\s+(.+)$", subject)
    if on:
        subject = on.group(1)
    elif re.match(
        r"(?i)^(?:portant|actualisant|renforçant|garantissant|modifiant|autorisant|créant|maintenant|mettant|améliorant|protégeant)\b",
        subject,
    ):
        return f"Êtes-vous favorable à une loi {subject[0].lower() + subject[1:]} ?"
    subject = subject[0].lower() + subject[1:]
    feminine = (
        "réforme",
        "protection",
        "création",
        "interdiction",
        "actualisation",
        "organisation",
        "prévention",
        "lutte",
        "sécurité",
        "suppression",
        "réduction",
        "augmentation",
        "revalorisation",
        "modernisation",
    )
    masculine = (
        "financement",
        "renforcement",
        "développement",
        "encadrement",
        "logement",
        "emploi",
        "budget",
        "accès",
        "soutien",
        "droit",
    )
    first = subject.split()[0]
    if first in feminine:
        subject = "la " + subject
    elif first in masculine:
        subject = ("l'" if first[0] in "aeiouéèêà" else "le ") + subject
    if subject.startswith("le "):
        return f"Êtes-vous favorable au {subject[3:]} ?"
    if subject.startswith("les "):
        return f"Êtes-vous favorable aux {subject[4:]} ?"
    if re.match(r"^(?:la |l'|un |une |des )", subject):
        return f"Êtes-vous favorable à {subject} ?"
    if re.match(r"^(?:de |du |des |d\')", subject):
        return f"Êtes-vous favorable à une loi {subject} ?"
    return f"Êtes-vous favorable au texte « {subject} » ?"


def normalized_subject(title: str) -> str:
    subject = subject_title(title)
    subject = re.sub(
        r"(?i)^(?:relati(?:f|ve|fs|ves) (?:à|au|aux)|visant à|tendant à|portant(?: sur)?)\s+",
        "",
        subject,
    )
    normalized = "".join(
        c
        for c in unicodedata.normalize("NFKD", subject.lower())
        if not unicodedata.combining(c)
    )
    return " ".join(re.findall(r"[a-z0-9]+", normalized))


def relevance_score(title: str, description: str) -> int:
    text = normalized_subject(f"{title} {description}")
    # One hit per theme prevents broad omnibus bills from dominating the feed.
    themes = [
        (
            "jeune",
            "etudiant",
            "ecole",
            "universite",
            "lycee",
            "education",
            "enseignement",
        ),
        ("numerique", "internet", "reseaux", "cyber", "harcelement"),
        ("climat", "ecologie", "environnement"),
        ("logement", "loyer"),
        ("emploi", "smic", "precarite", "inflation", "pouvoir d achat"),
        ("transport", "permis"),
        ("sante", "ivg", "avortement", "fin de vie"),
    ]
    score = sum(
        3
        for theme in themes
        if any(re.search(r"\b" + word + r"\b", text) for word in theme)
    )
    if any(
        word in text
        for word in ("ratification", "ordonnance", "approbation", "codification")
    ):
        score -= 5
    return score
