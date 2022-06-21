import os
import logging
from . import (
    log,
    get_arg_parser,
    add_args,
    upload_ui,
)


def main() -> None:
    parser = get_arg_parser()
    add_args(parser)
    args = parser.parse_args()
    if args.verbose:
        log.setLevel(logging.DEBUG)
    if None in (
        args.api_token,
        args.spaces_key,
        args.spaces_secret,
        args.spaces_name,
        args.spaces_path,
        args.ui_path,
        args.spaces_region,
    ):
        exit(parser.print_help())
    if not str(args.spaces_path).endswith("/"):
        exit(f"Error: spaces path {args.spaces_path} must end with a slash")
    if not os.path.isdir(args.ui_path):
        exit(f"Error: UI path {args.ui_path} does not exist")

    upload_ui(args)


if __name__ == "__main__":
    main()
