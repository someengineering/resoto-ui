import os
import logging
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
    parser.add_argument(
        "--test-build",
        "-t",
        help="Upload test build",
        action="store_true",
        default=False
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
    arg_parser.add_argument(
        "--github-event-name",
        help="Github Event Name",
        dest="github_event_name",
        default=os.getenv("GITHUB_EVENT_NAME", None),
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
