export interface User {
  id: string;
  email: string;
  firstName: string;
  lastName: string;
  cognitoSub: string;
  mfaEnabled: boolean;
  createdAt: Date;
  updatedAt: Date;
}

export interface AuthTokens {
  accessToken: string;
  refreshToken: string;
  expiresIn: number;
}

export interface RegisterRequest {
  email: string;
  password: string;
  firstName: string;
  lastName: string;
}

export interface LoginRequest {
  email: string;
  password: string;
}

export interface MfaSetupResponse {
  secretCode: string;
  qrCodeUrl: string;
}
