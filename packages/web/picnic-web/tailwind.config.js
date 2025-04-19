/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    './pages/**/*.{js,ts,jsx,tsx,mdx}',
    './components/**/*.{js,ts,jsx,tsx,mdx}',
    './app/**/*.{js,ts,jsx,tsx,mdx}',
  ],
  theme: {
    extend: {
      colors: {
        primary: {
          DEFAULT: '#9374FF',
          50: '#F5F2FF',
          100: '#E6DFFF',
          200: '#CCBDFF',
          300: '#B29AFF',
          400: '#9374FF',
          500: '#7A56FF',
          600: '#6138FD',
          700: '#491AE1',
          800: '#3712B3',
          900: '#260D7A',
        },
        secondary: {
          DEFAULT: '#83FBC8',
          50: '#EFFFFA',
          100: '#D4FFF0',
          200: '#AEFEE1',
          300: '#83FBC8',
          400: '#4FF7AD',
          500: '#1AED8D',
          600: '#0BC46B',
          700: '#089452',
          800: '#056339',
          900: '#033D23',
        },
        sub: {
          DEFAULT: '#CDFB5D',
          50: '#F9FFEB',
          100: '#F2FFCF',
          200: '#E6FEA0',
          300: '#CDFB5D',
          400: '#B8F31A',
          500: '#94D00A',
          600: '#6FA108',
          700: '#547505',
          800: '#3A5004',
          900: '#223001',
        },
        point: {
          DEFAULT: '#FFA9BD',
          50: '#FFF5F7',
          100: '#FFE5EC',
          200: '#FFD0DD',
          300: '#FFA9BD',
          400: '#FF809D',
          500: '#FF4D77',
          600: '#FF1A51',
          700: '#E6002E',
          800: '#B30024',
          900: '#7A0019',
        },
        point900: {
          DEFAULT: '#EB4A71',
        }
      }
    },
  },
  plugins: [],
} 