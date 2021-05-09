const fetch = require('node-fetch');
const functions = require('firebase-functions');
const stream = require('getstream');

const config = functions.config();
const getStreamClient = stream.connect(config.getstream.key, config.getstream.secret);

const AUTH0_DOMAIN = 'mhadaily.eu.auth0.com';
const AUTH0_ISSUER = `https://${AUTH0_DOMAIN}`;

const getAuth0UserInfo = async (authorization) => {
  const profileResponse = await fetch(`${AUTH0_ISSUER}/userinfo`, {
    method: 'GET',
    headers: { 'Content-Type': 'application/json', Authorization: `${authorization}` },
  });
  return await profileResponse.json();
};

const getAuth0ManagementTokens = async () => {
  const tokenResponse = await fetch(`${AUTH0_ISSUER}/oauth/token`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      client_id: `${config.auth0.key}`,
      client_secret: `${config.auth0.secret}`,
      audience: `${AUTH0_ISSUER}/api/v2/`,
      grant_type: 'client_credentials',
    }),
  });
  return await tokenResponse.json();
};

const getAuth0UserPermissions = async (profile, managementInfo) => {
  const permissionsResponse = await fetch(
    `${AUTH0_ISSUER}/api/v2/users/${profile.sub}/permissions`,
    {
      method: 'get',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `${managementInfo.token_type} ${managementInfo.access_token}`,
      },
    }
  );
  return await permissionsResponse.json();
};

const getAuth0UserRoles = async (profile, managementInfo) => {
  const rolesResponse = await fetch(`${AUTH0_ISSUER}/api/v2/users/${profile.sub}/roles`, {
    method: 'get',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `${managementInfo.token_type} ${managementInfo.access_token}`,
    },
  });
  return await rolesResponse.json();
};

const stripAllExceptNumbers = (str) => {
  return str.replace(/[^\d]/g, '');
};

module.exports.userProfile = functions.https.onRequest(async (request, response) => {
  try {
    const authorization = request.get('Authorization');
    const profile = await getAuth0UserInfo(authorization);
    const managementInfo = await getAuth0ManagementTokens();
    const permissions = await getAuth0UserPermissions(profile, managementInfo);
    const roles = await getAuth0UserRoles(profile, managementInfo);
    const getStreamToken = getStreamClient.createUserToken(`${stripAllExceptNumbers(profile.sub)}`);

    response.json({ ...profile, getStreamToken, permissions, roles });
  } catch (e) {
    // TODO:better error handling
    functions.logger.error(e);
    response.status(500).send({ error: 'Something is wrong!' });
  }
});

const getAuth0Users = async (managementInfo) => {
  const EMPLOYEE_ROLE_ID = 'rol_CHpJMdZUPCLzo6E2';
  const usersResponse = await fetch(`${AUTH0_ISSUER}/api/v2/roles/${EMPLOYEE_ROLE_ID}/users`, {
    method: 'get',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `${managementInfo.token_type} ${managementInfo.access_token}`,
    },
  });
  return await usersResponse.json();
};

module.exports.availableCustomerService = functions.https.onRequest(async (request, response) => {
  try {
    const managementInfo = await getAuth0ManagementTokens();
    const employees = await getAuth0Users(managementInfo);
    const randomIndex = Math.floor(Math.random() * employees.length);

    functions.logger.debug(employees[randomIndex]);

    response.json(stripAllExceptNumbers(employees[randomIndex]['user_id']));
  } catch (e) {
    // TODO:better error handling
    functions.logger.error(e);
    response.status(500).send({ error: 'Something is wrong!' });
  }
});
