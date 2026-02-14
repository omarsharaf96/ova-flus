import { Amplify } from 'aws-amplify';

export function configureAmplify() {
  Amplify.configure({
    Auth: {
      Cognito: {
        userPoolId: process.env.NEXT_PUBLIC_COGNITO_USER_POOL_ID || '',
        userPoolClientId: process.env.NEXT_PUBLIC_COGNITO_CLIENT_ID || '',
      },
    },
  });
}

export async function signIn(email: string, password: string) {
  const { signIn } = await import('aws-amplify/auth');
  return signIn({ username: email, password });
}

export async function signUp(email: string, password: string, displayName: string) {
  const { signUp } = await import('aws-amplify/auth');
  return signUp({
    username: email,
    password,
    options: { userAttributes: { name: displayName } },
  });
}

export async function signOut() {
  const { signOut } = await import('aws-amplify/auth');
  return signOut();
}

export async function getCurrentUser() {
  const { getCurrentUser } = await import('aws-amplify/auth');
  return getCurrentUser();
}
