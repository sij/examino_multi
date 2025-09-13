module.exports = {
  content: [
    "./app/views/**/*.html.erb",
    "./app/helpers/**/*.rb",
    "./app/javascript/**/*.js",
    "./app/components/**/*.erb"
  ],
  safelist: [
    'text-blue-500', 'text-green-500', 'text-yellow-500', 'text-purple-500', 'text-orange-500', 'text-gray-700', 'text-gray-500',
    'bg-blue-100', 'bg-green-100', 'bg-yellow-100', 'bg-purple-100', 'bg-orange-100', 'bg-gray-100',
    'border-blue-500', 'border-green-500', 'border-yellow-500', 'border-purple-500', 'border-orange-500', 'border-gray-500'
  ],
  theme: {
    extend: {},
  },
  plugins: [],
}