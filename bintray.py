#!/usr/bin/env python2
import argparse
import json
import sys

parser = argparse.ArgumentParser()
parser.add_argument('name')
parser.add_argument('version')
parser.add_argument('architecture')

args = parser.parse_args()

descriptor = {
    'files': [
        {
            'includePattern': r'aws-sdk-cpp/{}\.deb'.format(args.name),
            'matrixParams': {
                'deb_architecture': args.architecture,
                'deb_component': 'contrib',
                'deb_distribution': 'lucid',
            },
            'uploadPattern': r'pool/main/a/aws-sdk-cpp/{}_{}_{}.deb'.format(args.name, args.version, args.architecture),
        },
    ],
    'package': {
        'name': args.name,
        'repo': 'apt',
        'subject': 'lucidsoftware',
    },
    'publish': True,
    'version': {
        'gpgSign': True,
        'name': args.version,
        'vcs_tag': args.version,
    },
}
json.dump(descriptor, sys.stdout, indent=4)
