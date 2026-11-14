"""Build the Lambda deployment package deterministically using only stdlib."""

from pathlib import Path
from zipfile import ZIP_DEFLATED, ZipFile, ZipInfo

root = Path(__file__).resolve().parent
(root / ".build").mkdir(exist_ok=True)
for source, target in [
    ("lambda_function.py", "function.zip"),
    ("oauth_gateway.py", "oauth.zip"),
]:
    info = ZipInfo(source, date_time=(2020, 1, 1, 0, 0, 0))
    info.compress_type = ZIP_DEFLATED
    info.external_attr = 0o644 << 16
    with ZipFile(root / ".build" / target, "w") as archive:
        archive.writestr(info, (root / "lambda" / source).read_bytes())
