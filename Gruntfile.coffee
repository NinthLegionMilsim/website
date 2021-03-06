#global module:false
module.exports = (grunt) ->

	# Default task.
	@registerTask(
		"default"
		"Default task, that runs the production build"
		[
			"dist"
		]
	)

	@registerTask(
		"dist"
		"Produces the production files"
		[
			"checkDependencies"
			"build"
			"assemble"
			"htmlcompressor"
		]
	)

	#Alternate External tasks
	@registerTask(
		"debug"
		"Produces unminified files"
		[
			"build"
			"assemble:demos"
		]
	)

	@registerTask(
		"build"
		"Produces unminified files"
		[
			"clean:dist"
			"copy:wetboew"
			"assets"
			"css"
			"js"
		]
	)

	@registerTask(
		"init"
		"Only needed when the repo is first cloned"
		[
			"install-dependencies"
			"hub"
		]
	)

	@registerTask(
		"deploy"
		"Build and deploy artifacts to wet-boew-dist"
		[
			"copy:deploy"
			"gh-pages:travis"
		]
	)

	@registerTask(
		"server"
		"Run the Connect web server for local repo"
		[
			"connect:server:keepalive"
		]
	)

	@registerTask(
		"css"
		"INTERNAL: Compiles Sass and vendor prefixes the result"
		[
			"sass"
			"autoprefixer"
			"cssmin"
		]
	)

	@registerTask(
		"assets"
		"INTERNAL: Process non-CSS/JS assets to dist"
		[
			"copy:assets"
		]
	)

	@registerTask(
		"js"
		"INTERNAL: Brings in the custom JavaScripts."
		[
			"copy:js"
			"uglify"
		]
	)

	@initConfig

		# Metadata.
		pkg: @file.readJSON("package.json")
		themeDist: "dist/<%= pkg.name %>"
		jqueryVersion: grunt.file.readJSON("lib/jquery/bower.json")
		jqueryOldIEVersion: grunt.file.readJSON("lib/jquery-oldIE/bower.json")
		banner: "/*!\n * 9th Legion Milsim Website\n" +
				" * v<%= pkg.version %> - " + "<%= grunt.template.today('yyyy-mm-dd') %>\n *\n */"

		checkDependencies:
			all:
				options:
					npmInstall: false
		clean:
			dist: [ "dist"]

		copy:
			wetboew:
				expand: true
				cwd: "lib/wet-boew/dist"
				src: [
					"wet-boew/**/*.*"
				]
				dest: "dist"
			assets:
				files: [
						expand: true
						cwd: "src/assets"
						src: "**/*.*"
						dest: "<%= themeDist %>/assets"
					,
						expand: true
						cwd: "site/docs"
						src: "**/*.*"
						dest: "dist/docs"
					,
						expand: true
						cwd: "site/assets"
						src: "**/*.*"
						dest: "dist/assets"
				]
			js:
				expand: true
				cwd: "src/js"
				src: "**/*.js"
				dest: "<%= themeDist %>/js"
			deploy:
				expand: true
				src: "CNAME"
				dest: "dist"

		sass:
			base:
				expand: true
				cwd: "src/sass"
				src: "*theme.scss"
				dest: "<%= themeDist %>/css"
				ext: ".css"

		autoprefixer:
			options:
				browsers: [
					"last 2 versions"
					"ff >= 17"
					"opera 12.1"
					"bb >= 7"
					"android >= 2.3"
					"ie >= 8"
					"ios 5"
				]
			all:
				cwd: "<%= themeDist %>/css"
				src: [
					"**/*.css"
					"!**/*.min.css"
				]
				dest: "<%= themeDist %>/css"
				expand: true
				flatten: true

		cssmin:
			options:
				banner: "@charset \"utf-8\";\n<%= banner %>"
			dist:
				cwd: "<%= themeDist %>/css"
				src: [
					"**/*.css"
					"!**/wet-boew.css"
					"!**/ie8-wet-boew.css"
					"!**/*.min.css"
				]
				ext: ".min.css"
				dest: "<%= themeDist %>/css"
				expand: true

		# Minify
		uglify:
			dist:
				options:
					banner: "<%= banner %>"
				expand: true
				cwd: "<%= themeDist %>/js/"
				src: ["*.js"]
				dest: "<%= themeDist %>/js/"
				ext: ".min.js"

		assemble:
			options:
				prettify:
					indent: 2
				marked:
					sanitize: false
				production: false
				data: [
					"lib/wet-boew/site/data/**/*.{yml,json}"
					"site/data/**/*.{yml,json}"
				]
				helpers: [
					"lib/wet-boew/site/helpers/helper-*.js"
					"site/helpers/helper-*.js"
				]
				partials: [
					"lib/wet-boew/site/includes/**/*.hbs"
					"site/includes/**/*.hbs"
				]
				layoutdir: "site/layouts"
				layout: "default.hbs"

			demos:
				options:
					environment:
						suffix: ".min"
						jqueryVersion: "<%= jqueryVersion.version %>"
						jqueryOldIEVersion: "<%= jqueryOldIEVersion.version %>"
					assets: "dist"
				files: [
						#site
						expand: true
						cwd: "site/pages"
						src: [
							"*.hbs",
						]
						dest: "dist"
				]

		htmlcompressor:
			options:
				type: "html"
				concurrentProcess: 5
			all:
				cwd: "dist"
				src: [
					"**/*.html"
					"!unmin/**/*.html"
				]
				dest: "dist"
				expand: true

		hub:
			"wet-boew":
				src: [
					"lib/wet-boew/Gruntfile.coffee"
				]
				tasks: [
					"dist"
				]

		"install-dependencies":
			options:
				cwd: "lib/wet-boew"
				failOnError: true
				isDevelopment: true

		connect:
			options:
				port: 8000

			server:
				options:
					base: "dist"
					middleware: (connect, options, middlewares) ->
						middlewares.unshift(connect.compress(
							filter: (req, res) ->
								/json|text|javascript|dart|image\/svg\+xml|application\/x-font-ttf|application\/vnd\.ms-opentype|application\/vnd\.ms-fontobject/.test(res.getHeader('Content-Type'))
						))
						middlewares

		"gh-pages":
			options:
				clone: "github_io"
				base: "dist"

			travis:
				options:
					repo: process.env.DIST_REPO
					branch: "master"
					message: "Travis build " + process.env.TRAVIS_BUILD_NUMBER
				src: [
					"**/*"
					"!unmin/**/*.*"
				]

	# These plugins provide necessary tasks.
	@loadNpmTasks "assemble"
	@loadNpmTasks "grunt-autoprefixer"
	@loadNpmTasks "grunt-check-dependencies"
	@loadNpmTasks "grunt-contrib-clean"
	@loadNpmTasks "grunt-contrib-connect"
	@loadNpmTasks "grunt-contrib-copy"
	@loadNpmTasks "grunt-contrib-cssmin"
	@loadNpmTasks "grunt-contrib-uglify"
	@loadNpmTasks "grunt-contrib-watch"
	@loadNpmTasks "grunt-gh-pages"
	@loadNpmTasks "grunt-htmlcompressor"
	@loadNpmTasks "grunt-hub"
	@loadNpmTasks "grunt-install-dependencies"
	@loadNpmTasks "grunt-sass"

	@
