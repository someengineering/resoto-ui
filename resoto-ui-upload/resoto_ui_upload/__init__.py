import os
import re
import glob
import logging
import time
from functools import lru_cache
from argparse import ArgumentParser, Namespace
from typing import Optional, Any

try:
    import boto3
    import requests
    from botocore.client import BaseClient
except ImportError:
    BaseClient = Any

"""
Resoto UI upload
~~~~~~~~~~~~~~~~
Tool to upload the Resoto UI to the CDN.
:copyright: © 2022 Some Engineering Inc.
:license: Apache 2.0, see LICENSE for more details.
"""

__title__ = "resoto-ui-upload"
__description__ = "Resoto UI upload."
__author__ = "Some Engineering Inc."
__license__ = "Apache 2.0"
__copyright__ = "Copyright © 2022 Some Engineering Inc."
__version__ = "2.3.0a0"


logging.basicConfig(
    level=logging.INFO,
    format="%(levelname)s - %(message)s",
)
log = logging.getLogger("resoto-ui-upload")
log.setLevel(logging.INFO)


def upload_ui(args: Namespace) -> None:
    """Upload the Resoto UI to the CDN."""
    log.info("Uploading Resoto UI to the CDN")
    client = s3_client(args.spaces_region, args.spaces_key, args.spaces_secret)
    local_ui_path = os.path.abspath(args.ui_path)

    # github_ref format:
    # refs/tags/v0.0.1
    # refs/heads/master
    destinations = ["edge"]
    if not None in (args.github_ref, args.github_ref_type):
        m = re.search(r"^refs/(heads|tags)/(.+)$", str(args.github_ref))
        if m:
            destination = m.group(2)
            if args.github_ref_type == "tag":
                destinations = ["latest", destination]

    purge_keys = []
    for destination in destinations:
        for filename in glob.iglob(local_ui_path + "**/**", recursive=True):
            if not os.path.isfile(filename):
                continue
            basename = filename[len(local_ui_path) + 1 :]
            key_name = f"{args.spaces_path}{destination}/{basename}"
            log.debug(f"Uploading {filename} to {key_name}")
            upload_file(client, filename, key_name, args.spaces_name)
            purge_keys.append(key_name)
    purge_cdn(purge_keys, args.api_token, args.spaces_name, args.spaces_region)


def s3_client(region: str, key: str, secret: str) -> BaseClient:
    session = boto3.session.Session()
    return session.client(
        "s3",
        region_name=region,
        endpoint_url=f"https://{region}.digitaloceanspaces.com",
        aws_access_key_id=key,
        aws_secret_access_key=secret,
    )


def upload_file(client: BaseClient, filename: str, key: str, spaces_name: str, acl: str = "public-read") -> None:
    with open(filename, "rb") as f:
        client.upload_fileobj(f, spaces_name, key, ExtraArgs={"ACL": acl})


def purge_cdn(files: list, api_token: str, spaces_name: str, region: str) -> None:
    """Purge the CDN cache for the given files."""
    endpoints = cdn_endpoints(api_token, ttl_hash=ttl_hash())
    log.info(f"Purging CDN cache for {len(files)} files")
    endpoint_key = f"{spaces_name}.{region}.digitaloceanspaces.com"
    if endpoint_key not in endpoints:
        raise RuntimeError(f"No CDN endpoint for {endpoint_key}")
    endpoint_id = endpoints[endpoint_key]
    headers = {"Authorization": f"Bearer {api_token}", "Content-Type": "application/json"}
    data = {"files": files}
    response = requests.delete(
        f"https://api.digitalocean.com/v2/cdn/endpoints/{endpoint_id}/cache", json=data, headers=headers
    )
    if response.status_code != 204:
        raise RuntimeError(f"failed to purge CDN cache: {response.status_code} {response.text}")


@lru_cache(maxsize=1)
def cdn_endpoints(api_token: str, ttl_hash: Optional[int] = None) -> dict:
    """Get the CDN endpoint from the DigitalOcean API."""
    log.debug("Getting all CDN endpoints from the DigitalOcean API")
    headers = {"Authorization": f"Bearer {api_token}", "Content-Type": "application/json"}

    endpoints = {}
    next_uri = "https://api.digitalocean.com/v2/cdn/endpoints?per_page=200"
    while True:
        response = requests.get(next_uri, headers=headers)
        if response.status_code != 200:
            raise RuntimeError(f"failed to get CDN endpoint: {response.text}")
        data = response.json()
        if not "endpoints" in data:
            raise ValueError(f"no CDN endpoint in response: {response.text}")
        for endpoint in data["endpoints"]:
            endpoints[endpoint["origin"]] = endpoint["id"]
        if data.get("links", {}).get("pages", {}).get("next", None) is None:
            break
        next_uri = data["links"]["pages"]["next"]
    return endpoints


def ttl_hash(ttl: int = 3600) -> int:
    return round(time.time() / ttl)


def get_arg_parser() -> ArgumentParser:
    parser = ArgumentParser(description="Resoto UI upload")
    parser.add_argument(
        "--verbose",
        "-v",
        help="Verbose logging",
        dest="verbose",
        action="store_true",
        default=False,
    )
    return parser


def add_args(arg_parser: ArgumentParser) -> None:
    arg_parser.add_argument(
        "--api-token",
        help="DigitalOcean API token - to purge the CDN cache",
        dest="api_token",
        default=os.getenv("API_TOKEN", None),
    )
    arg_parser.add_argument(
        "--spaces-key",
        help="DigitalOcean Spaces Key",
        dest="spaces_key",
        default=os.getenv("SPACES_KEY", None),
    )
    arg_parser.add_argument(
        "--spaces-secret",
        help="DigitalOcean Spaces Secret",
        dest="spaces_secret",
        default=os.getenv("SPACES_SECRET", None),
    )
    arg_parser.add_argument(
        "--spaces-region",
        help="DigitalOcean Spaces Region",
        dest="spaces_region",
        default=os.getenv("SPACES_REGION", None),
    )
    arg_parser.add_argument(
        "--spaces-name",
        help="DigitalOcean Spaces name - the bucket name",
        dest="spaces_name",
        default=os.getenv("SPACES_NAME", None),
    )
    arg_parser.add_argument(
        "--ui-path",
        help="Local UI path - path where the UI was built",
        dest="ui_path",
        default=os.getenv("UI_PATH", None),
    )
    arg_parser.add_argument(
        "--spaces-path",
        help="DigitalOcean Spaces UI path - path where the UI is stored",
        dest="spaces_path",
        default=os.getenv("SPACES_PATH", None),
    )
    arg_parser.add_argument(
        "--github-ref",
        help="Github Ref",
        dest="github_ref",
        default=os.getenv("GITHUB_REF", None),
    )
    arg_parser.add_argument(
        "--github-ref-type",
        help="Github Ref Type",
        dest="github_ref_type",
        default=os.getenv("GITHUB_REF_TYPE", None),
    )


def verify_args(args: Namespace) -> None:
    if None in (
        args.api_token,
        args.spaces_key,
        args.spaces_secret,
        args.spaces_name,
        args.spaces_path,
        args.ui_path,
        args.spaces_region,
    ):
        raise ValueError("missing required argument")
    if not str(args.spaces_path).endswith("/"):
        raise ValueError(f"spaces path {args.spaces_path} must end with a slash")
    if str(args.spaces_path).startswith("/"):
        raise ValueError(f"spaces path {args.spaces_path} must not start with a slash")
    if not os.path.isdir(args.ui_path):
        raise ValueError(f"UI path {args.ui_path} does not exist")
