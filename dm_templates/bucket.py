def generate_config(context):
    resource = {
        'type': 'storage.v1.bucket',
        'name': context.properties['SUBDOMAIN'],
        'properties': {
            'location': context.properties['GCP_REGION'],
            'website': {
                'mainPageSuffix': context.properties['MAIN_PAGE'],
                'notFoundPage': context.properties['NOT_FOUND_PAGE'],
            },
            'iamConfiguration': {
                'uniformBucketLevelAccess': {
                    'enabled': True,
                },
                'publicAccessPrevention': 'unspecified',
            }
        },
        'accessControl': {
            'gcpIamPolicy': {
                'bindings': [
                    {
                        'role': 'roles/storage.objectViewer',
                        'members': [
                            'allUsers',
                        ],
                    },
                    {
                        'role': 'roles/storage.admin',
                        'members': [
                            f'serviceAccount:{context.env["project_number"]}@cloudservices.gserviceaccount.com',
                            f'projectOwner:{context.env["project"]}',
                        ],
                    },
                ],
            },
        },
    }
    return {'resources': [resource]}
