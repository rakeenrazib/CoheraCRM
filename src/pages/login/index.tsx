import { AuthPage } from "@refinedev/antd";
import { authCredentials } from "../../providers";
//import Password from "antd/es/input/Password";

export const Login = () => {
  return (
    <AuthPage
    type= "login"
    formProps={{
      initialValues: authCredentials,
    }}
    />
  );
};