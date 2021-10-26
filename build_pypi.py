import os
from hashlib import sha256
from pathlib import Path

from dumb_pypi.main import Settings, build_repo, Package


def sha256sum(file: Path):
    h = sha256()
    b = bytearray(128 * 1024)
    mv = memoryview(b)
    with file.open("rb", buffering=0) as f:
        for n in iter(lambda: f.readinto(mv), 0):
            h.update(mv[:n])
    return h.hexdigest()


def main():
    wheels_dir = Path(os.getcwd()) / "wheels"
    output_dir = wheels_dir / "pypi"

    packages = {}
    for file in wheels_dir.glob("*.whl"):
        package = Package.create(filename=file.name, hash=f"sha256={sha256sum(file)}")
        packages.setdefault(package.name, set()).add(package)

    settings = Settings(
        output_dir=str(output_dir),
        packages_url="/",
        title=None,
        logo=None,
        logo_width=None,
        generate_timestamp=None,
    )
    build_repo(packages, settings)


if __name__ == "__main__":
    main()
