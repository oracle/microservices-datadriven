import { Link } from "react-router-dom";
import "../Css/styles.css";

const Error = () => {
  return (
    <section className="form">
      <h2>404</h2>
      <p>page not found</p>
      <Link to="/">back home</Link>
    </section>
  );
};
export default Error;
