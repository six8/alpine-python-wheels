import os
from hashlib import sha256
from pathlib import Path
import requests
from dumb_pypi.main import Settings, build_repo, Package


class ExactUrlPackage(Package):
    _url: str

    def url(self, base_url: str, *, include_hash: bool = True) -> str:
        hash_part = f"#{self.hash}" if self.hash and include_hash else ""
        return f"{self._url}{hash_part}"


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

        # Include packages that pypi hosts. The files will be served from pypi
        # and are indexed here so poetry can find them.
        response = requests.get(
            f"https://pypi.org/pypi/{package.name}/{package.version}/json"
        ).json()
        for url in response["urls"]:
            package = ExactUrlPackage.create(
                filename=url["filename"],
                hash=f"sha256={url['digests']['sha256']}",
                requires_python=url["requires_python"],
            )
            package._url = url["url"]
            packages[package.name].add(package)

    settings = Settings(
        output_dir=str(output_dir),
        packages_url="../../../",
        title=None,
        logo=None,
        logo_width=None,
        generate_timestamp=None,
    )
    build_repo(packages, settings)


if __name__ == "__main__":
    main()
