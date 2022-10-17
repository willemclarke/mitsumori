/** @type {import('tailwindcss').Config} */
module.exports = {
  content: ["./src/**/*.elm", "./src/**/*.js", "./src/**/*.ts", "./index.html"],
  theme: {
    extend: {},
  },
  plugins: [require("tailwindcss-animate")],
  animation: {
    "slide-in": "slide 300ms ease-out forwards",
  },
  keyframes: {
    slide: {
      to: { transform: "translate(0px)" },
    },
  },
};
