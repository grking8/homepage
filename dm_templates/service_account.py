def generate_config(context):
    service_account_name = context.properties['GCP_RESOURCE_SERVICE_ACCOUNT']
    service_account_resource = {
        'type': 'iam.v1.serviceAccount',
        'name': service_account_name,
        'properties': {
            'accountId': service_account_name,
            'displayName': 'Resource service account impersonated in CI in order to update deployment',
        },
        'accessControl': {
            'gcpIamPolicy': {
                'bindings': [
                    {
                        'role': 'roles/iam.serviceAccountTokenCreator',
                        'members': [
                            f'serviceAccount:{context.properties["GCP_IDENTITY_SERVICE_ACCOUNT_EMAIL"]}',
                        ]
                    },
                ]
            },
        },
    }
    iam_member_binding_resource = {
        'type': 'gcp-types/cloudresourcemanager-v1:virtual.projects.iamMemberBinding',
        'name': f'{service_account_name}-iam-policy',
        'properties': {
            'resource': context.env["project"],
            'role': 'roles/storage.admin',
            'member': 'serviceAccount:$(ref.' + service_account_name + '.email)',
        },
        'metadata': {
            'dependsOn': [service_account_name],
        },
    }
    resources = [
        service_account_resource,
        iam_member_binding_resource,
    ]
    return {'resources': resources}
