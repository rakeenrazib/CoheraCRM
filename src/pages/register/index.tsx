import { AuthPage } from "@refinedev/antd";
//import Password from "antd/es/input/Password";

export const Register = () => {
  return (
    <AuthPage
    type= "register"
    formProps={{
      initialValues: { email: "michaeljordan@nike.com", Password: "demodemo"},
    }}
    />
  );
};