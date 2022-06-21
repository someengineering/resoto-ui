import os
import logging
import boto3
import glob
from argparse import ArgumentParser, Namespace

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
    session = boto3.session.Session()
    client = session.client(
        "s3",
        region_name=args.spaces_region,
        endpoint_url=f"https://{args.spaces_region}.digitaloceanspaces.com",
        aws_access_key_id=args.spaces_key,
        aws_secret_access_key=args.spaces_secret,
    )
    local_ui_path = os.path.abspath(args.ui_path)
    for filename in glob.iglob(local_ui_path + "**/**", recursive=True):
        if not os.path.isfile(filename):
            continue
        key_name = args.spaces_path + filename[len(local_ui_path) + 1 :]
        log.debug(f"Uploading {filename} to {key_name}")
        upload_file(client, filename, key_name, args.spaces_name)


def upload_file(
    client: "botocore.client.S3", filename: str, key: str, spaces_name: str, acl: str = "public-read"
) -> None:
    with open(filename, "rb") as f:
        client.upload_fileobj(f, spaces_name, key, ExtraArgs={"ACL": acl})


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
