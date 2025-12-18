/** @type {import('tailwindcss').Config} */
module.exports = {
  darkMode: 'class',
  content: [
    "./src/**/*.{html,ts}",
  ],
  theme: {
    extend: {
      colors: {
        "primary": "#f9f506",
        "background-light": "#f8f8f5",
        "background-dark": "#23220f",
        "surface-light": "#ffffff",
        "surface-dark": "#2d2c15",
        "border-light": "#e2e8f0",
        "border-dark": "#3f3f46",
        "text-main": "#1c1c0d",
        "text-secondary": "#5f5e4e",
        "text-muted": "#9e9d47",
        "text-primary-light": "#1c1c0d",
        "text-secondary-light": "#5f5e4e",
        "text-primary-dark": "#e8e6d9",
        "text-secondary-dark": "#a09f8d",
        "accent-success": "#078816",
        "accent-error": "#e71708",
        "accent-warning": "#eab308",
        "accent-info": "#0ea5e9",
      },
      fontFamily: {
        "display": ["Spline Sans", "sans-serif"]
      },
      borderRadius: {
        "DEFAULT": "1rem", 
        "lg": "1.5rem", 
        "xl": "2rem", 
        "2xl": "2.5rem",
        "3xl": "3rem",
        "full": "9999px"
      },
      boxShadow: {
        'soft': '0 4px 20px -2px rgba(0, 0, 0, 0.05)',
      }
    },
  },
  plugins: [],
}
