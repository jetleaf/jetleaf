import { createRoot } from "react-dom/client";
import "./styles/index.css";
import { TrendingUp, Github, Menu, X, Compass, Zap, CheckCircle, ArrowRight, Heart } from "lucide-react";
import { useEffect, useState } from 'react'
import { Button } from "./components/button.tsx";
import { Card } from "./components/card.tsx";
import { codeToHtml } from 'shiki'

createRoot(document.getElementById("root")!).render(<LandingPage />);

/**
 * Example Dart entrypoint shown in the hero code preview.
 *
 * Displayed using Shiki syntax highlighting via `useShiki`.
 */
const entryCode = `
import 'package:jetleaf/jetleaf.dart';

void main(List<String> args) async {
   await JetleafApplication.run(ExampleApplication(), args);
}

@Component()
class NotificationService {
  final Notifier notifier;

  NotificationService(@Qualifier('smsOtherNotifier') this.notifier);
}

@Component('smsOtherNotifier')
class SmsNotifier implements Notifier {
  void send(String msg) => print("SMS: $msg");
}

@Component('emailOtherNotifier')
class EmailNotifier implements Notifier {
  void send(String msg) => print("Email: $msg");
}
`;

/**
 * Renders the main marketing landing page for Jetleaf.
 *
 * This page includes:
 * - A hero section introducing Jetleaf and its core value proposition.
 * - A highlighted announcement badge for the latest framework release.
 * - A syntax-highlighted Dart entrypoint preview using Shiki.
 * - A call-to-action button for starting a new project.
 * - A persistent header and footer for navigation continuity.
 *
 * No internal state is stored in this component — it is fully driven by props.
 *
 * @param onNavigate - Used to request navigation to other application areas.
 * @returns A complete landing layout with hero, code preview, and footer.
 */
function LandingPage() {
    return (
        <div className="min-h-screen bg-white">
            {/* Persistent site header with navigation */}
            <Header />

            {/* Hero Section — includes marketing copy, CTA, and code preview */}
            <section className="relative overflow-hidden">
                {/* Decorative gradient and blurred background shapes */}
                <div className="absolute inset-0 bg-gradient-to-br from-green-50 via-emerald-50/30 to-white -z-10" />
                <div className="absolute top-0 right-0 w-1/2 h-full opacity-10">
                    <div className="absolute top-20 right-20 w-72 h-72 bg-green-500 rounded-full blur-3xl" />
                    <div className="absolute bottom-20 right-40 w-96 h-96 bg-emerald-500 rounded-full blur-3xl" />
                </div>

                <div className="max-w-7xl mx-auto px-4 py-20 md:py-28">
                    <div className="grid grid-cols-1 lg:grid-cols-2 gap-12 items-center">
                        {/* Hero text content and call-to-action */}
                        <div>
                            {/* Version announcement badge */}
                            <div className="inline-flex items-center gap-2 px-4 py-2 bg-green-100 text-green-700 rounded-full mb-6">
                                <TrendingUp className="w-4 h-4" />
                                <span className="text-sm">Jetleaf v1.0.1 is now available</span>
                            </div>

                            <h1 className="text-5xl md:text-6xl mb-6 text-gray-900 leading-tight">
                                Build Scalable, Annotation-Driven Web Applications with{' '}
                                <span className="text-green-600">Dart</span>
                            </h1>

                            <p className="text-xl text-gray-600 mb-8 leading-relaxed">
                                Jetleaf is a modern, annotation-driven framework that makes building scalable web applications fast,
                                reliable, and enjoyable. Start your project in minutes with our intuitive project builder.
                            </p>

                            {/* Primary CTA — navigates into project creation flow */}
                            <div className="flex flex-col sm:flex-row gap-4">
                                <Button
                                    size="sm"
                                    onClick={() => window.open("https://create.jetleaf.hapnium.com")}
                                    className="text-sm px-8"
                                >
                                    Create Your Project
                                    <ArrowRight className="w-5 h-5 ml-2" />
                                </Button>
                            </div>
                        </div>

                        {/* Code Preview Card — syntax-highlighted Dart snippet */}
                        <div className="relative">
                            <Card className="p-6 shadow-2xl bg-gray-900 border-gray-800">
                                {/* Window chrome indicators */}
                                <div className="flex items-center gap-2">
                                    <div className="w-3 h-3 rounded-full bg-red-500" />
                                    <div className="w-3 h-3 rounded-full bg-yellow-500" />
                                    <div className="w-3 h-3 rounded-full bg-green-500" />
                                    <span className="ml-2 text-sm text-gray-400">main.dart</span>
                                </div>

                                {/* Render highlighted code HTML from Shiki */}
                                <div className="rounded-lg overflow-x-auto">
                                    <div
                                        className="text-sm"
                                        dangerouslySetInnerHTML={{
                                            __html: useShiki(entryCode, 'dart', 'vitesse-dark'),
                                        }}
                                    />
                                </div>
                            </Card>

                            {/* Badge indicating production-readiness */}
                            <div className="absolute -bottom-4 -right-4 bg-white p-4 rounded-lg shadow-xl border border-gray-200">
                                <div className="flex items-center gap-2">
                                    <CheckCircle className="w-5 h-5 text-green-600" />
                                    <span className="text-sm">Production Ready</span>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </section>

            {/* Persistent footer controls */}
            <Footer />
        </div>
    );
}

/**
 * Header component for the Jetleaf framework landing page.
 * 
 * Features:
 * - Displays a logo with branding (Jetleaf Framework)
 * - Responsive navigation:
 *   - Desktop: horizontal navigation buttons (currently partially commented out)
 *   - Mobile: collapsible menu toggled with a hamburger icon
 * - Primary actions: "Start Building" button and "Star on GitHub"
 * - Uses Tailwind for styling and Lucide icons
 */
function Header() {
    const [mobileMenuOpen, setMobileMenuOpen] = useState(false);

    const navItems = [
        { label: 'Overview', page: 'overview', icon: <Compass className="w-4 h-4" /> },
        // { label: 'Documentation', page: 'documentation', icon: <BookOpen className="w-4 h-4" /> },
        // { label: 'Community', page: 'community', icon: <GitBranch className="w-4 h-4" /> },
    ];

    return (
        <header className="bg-white/80 backdrop-blur-lg border-b border-gray-200/50 sticky top-0 z-50 shadow-sm">
            <div className="max-w-7xl mx-auto px-4">
                <div className="flex items-center justify-between h-16">
                    {/* Logo */}
                    <button
                        type="button"
                        style={{ cursor: "pointer" }}
                        className="flex items-center gap-3 group hover:opacity-90 transition-all"
                    >
                        <img alt='logo' src='logo.png' height={50} width={50} />
                        <div className="flex flex-col items-start">
                            <span className="text-xl tracking-tight">Jetleaf</span>
                            <span className="text-xs text-green-600 -mt-1">Framework</span>
                        </div>
                    </button>

                    {/* Desktop Navigation */}
                    <nav className="hidden md:flex items-center gap-1">
                        {/* {navItems.map((item) => (
              <button
                key={item.page}
                onClick={() => onNavigate(item.page)}
                className="flex items-center gap-2 px-4 py-2 rounded-lg text-gray-600 hover:text-green-600 hover:bg-green-50 transition-all group"
              >
                <span className="opacity-0 group-hover:opacity-100 transition-opacity">
                  {item.icon}
                </span>
                <span>{item.label}</span>
              </button>
            ))} */}

                        <div className="w-px h-6 bg-gray-300 mx-2" />

                        <Button
                            size="sm"
                            onClick={() => window.open("https://create.jetleaf.hapnium.com")}
                            className="ml-2 bg-gradient-to-r from-green-600 to-emerald-600 hover:from-green-700 hover:to-emerald-700 shadow-md hover:shadow-lg transition-all"
                        >
                            <Zap className="w-4 h-4 mr-2" />
                            Start Building
                        </Button>

                        <Button onClick={() => window.open('https://github.com/jetleaf', '_blank')} variant="outline" size="sm" className="ml-2 border-gray-300 hover:border-green-600 hover:text-green-600">
                            <Github className="w-4 h-4 mr-2" />
                            Star on GitHub
                        </Button>
                    </nav>

                    {/* Mobile Menu Button */}
                    <button
                        className="md:hidden p-2 hover:bg-gray-100 rounded-lg transition-colors"
                        onClick={() => setMobileMenuOpen(!mobileMenuOpen)}
                    >
                        {mobileMenuOpen ? (
                            <X className="w-6 h-6" />
                        ) : (
                            <Menu className="w-6 h-6" />
                        )}
                    </button>
                </div>

                {/* Mobile Navigation */}
                {mobileMenuOpen && (
                    <nav className="md:hidden py-4 border-t border-gray-200">
                        <div className="flex flex-col gap-2">
                            {navItems.map((item) => (
                                <button
                                    key={item.page}
                                    type="button"
                                    onClick={() => {
                                        window.open(item.page);
                                        setMobileMenuOpen(false);
                                    }}
                                    className="flex items-center gap-3 px-4 py-3 rounded-lg text-gray-600 hover:text-green-600 hover:bg-green-50 transition-all text-left"
                                >
                                    {item.icon}
                                    <span>{item.label}</span>
                                </button>
                            ))}

                            <div className="h-px bg-gray-200 my-2" />

                            <Button
                                className="w-full bg-gradient-to-r from-green-600 to-emerald-600 hover:from-green-700 hover:to-emerald-700"
                                onClick={() => {
                                    window.open("https://create.jetleaf.hapnium.com");
                                    setMobileMenuOpen(false);
                                }}
                            >
                                <Zap className="w-4 h-4 mr-2" />
                                Start Building
                            </Button>

                            <Button variant="outline" className="w-full">
                                <Github className="w-4 h-4 mr-2" />
                                Star on GitHub
                            </Button>
                        </div>
                    </nav>
                )}
            </div>
        </header>
    );
}

/**
 * Footer component for the Jetleaf website.
 *
 * Features:
 * - Decorative top border gradient
 * - Brand information: logo, title, and description
 * - Copyright section with Heart icon
 * - (Optional/Commented out) Columns for Learn, Tools, Community, Resources
 * - (Optional/Commented out) Newsletter subscription
 * - (Optional/Commented out) Social links and legal links
 * - Background visual decoration
 *
 * Designed to be responsive with grid layout on desktop (6 columns)
 * and stacked layout on smaller screens.
 */
export function Footer() {
    return (
        <footer className="relative bg-gradient-to-br from-gray-900 via-gray-800 to-gray-900 text-gray-300">
            {/* Decorative top border */}
            <div className="absolute top-0 left-0 right-0 h-1 bg-gradient-to-r from-green-500 via-emerald-500 to-green-500" />

            <div className="max-w-7xl mx-auto px-4 pt-16 pb-8">
                {/* Main Footer Content */}
                <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-6 gap-8 mb-12">
                    {/* Brand Column */}
                    <div className="lg:col-span-2">
                        <div className="flex items-center gap-3 mb-4">
                            <img alt='logo' src='logo.png' height={50} width={50} />
                            <div className="flex flex-col">
                                <span className="text-white text-xl tracking-tight">Jetleaf</span>
                                <span className="text-xs text-green-400 -mt-1">Enterprise Dart Framework</span>
                            </div>
                        </div>
                        <p className="text-sm text-gray-400 mb-6 leading-relaxed">
                            Build modern, scalable web applications with Dart. The enterprise-grade framework trusted by developers worldwide.
                        </p>

                        {/* Newsletter */}
                        {/* <div className="space-y-3">
              <p className="text-sm text-white">Subscribe to our newsletter</p>
              <div className="flex gap-2">
                <Input 
                  placeholder="Enter your email" 
                  className="bg-gray-800 border-gray-700 text-white placeholder:text-gray-500 focus:border-green-500"
                />
                <Button size="sm" className="bg-green-600 hover:bg-green-700 shrink-0">
                  <ArrowRight className="w-4 h-4" />
                </Button>
              </div>
            </div> */}
                    </div>

                    {/* Learn Column */}
                    {/* <div>
            <h4 className="text-white mb-4 flex items-center gap-2">
              <span className="w-1 h-4 bg-green-500 rounded-full" />
              Learn
            </h4>
            <ul className="space-y-3 text-sm">
              <li>
                <button
                  onClick={() => onNavigate('overview')}
                  className="hover:text-green-400 transition-colors flex items-center gap-2 group"
                >
                  <span className="opacity-0 group-hover:opacity-100 transition-opacity">→</span>
                  <span>Overview</span>
                </button>
              </li>
              <li>
                <button
                  onClick={() => onNavigate('documentation')}
                  className="hover:text-green-400 transition-colors flex items-center gap-2 group"
                >
                  <span className="opacity-0 group-hover:opacity-100 transition-opacity">→</span>
                  <span>Documentation</span>
                </button>
              </li>
              <li>
                <a href="#" className="hover:text-green-400 transition-colors flex items-center gap-2 group">
                  <span className="opacity-0 group-hover:opacity-100 transition-opacity">→</span>
                  <span>API Reference</span>
                </a>
              </li>
              <li>
                <a href="#" className="hover:text-green-400 transition-colors flex items-center gap-2 group">
                  <span className="opacity-0 group-hover:opacity-100 transition-opacity">→</span>
                  <span>Guides & Tutorials</span>
                </a>
              </li>
              <li>
                <a href="#" className="hover:text-green-400 transition-colors flex items-center gap-2 group">
                  <span className="opacity-0 group-hover:opacity-100 transition-opacity">→</span>
                  <span>Examples</span>
                </a>
              </li>
            </ul>
          </div> */}

                    {/* Tools Column */}
                    {/* <div>
            <h4 className="text-white mb-4 flex items-center gap-2">
              <span className="w-1 h-4 bg-emerald-500 rounded-full" />
              Tools
            </h4>
            <ul className="space-y-3 text-sm">
              <li>
                <button
                  onClick={() => onNavigate('start')}
                  className="hover:text-green-400 transition-colors flex items-center gap-2 group"
                >
                  <span className="opacity-0 group-hover:opacity-100 transition-opacity">→</span>
                  <span>Start Project</span>
                </button>
              </li>
              <li>
                <a href="#" className="hover:text-green-400 transition-colors flex items-center gap-2 group">
                  <span className="opacity-0 group-hover:opacity-100 transition-opacity">→</span>
                  <span>Package Registry</span>
                </a>
              </li>
              <li>
                <a href="#" className="hover:text-green-400 transition-colors flex items-center gap-2 group">
                  <span className="opacity-0 group-hover:opacity-100 transition-opacity">→</span>
                  <span>CLI Tools</span>
                </a>
              </li>
              <li>
                <a href="#" className="hover:text-green-400 transition-colors flex items-center gap-2 group">
                  <span className="opacity-0 group-hover:opacity-100 transition-opacity">→</span>
                  <span>VS Code Extension</span>
                </a>
              </li>
              <li>
                <a href="#" className="hover:text-green-400 transition-colors flex items-center gap-2 group">
                  <span className="opacity-0 group-hover:opacity-100 transition-opacity">→</span>
                  <span>Templates</span>
                </a>
              </li>
            </ul>
          </div> */}

                    {/* Community Column */}
                    {/* <div>
            <h4 className="text-white mb-4 flex items-center gap-2">
              <span className="w-1 h-4 bg-blue-500 rounded-full" />
              Community
            </h4>
            <ul className="space-y-3 text-sm">
              <li>
                <button
                  onClick={() => onNavigate('community')}
                  className="hover:text-green-400 transition-colors flex items-center gap-2 group"
                >
                  <span className="opacity-0 group-hover:opacity-100 transition-opacity">→</span>
                  <span>Community Hub</span>
                </button>
              </li>
              <li>
                <a href="#" className="hover:text-green-400 transition-colors flex items-center gap-2 group">
                  <span className="opacity-0 group-hover:opacity-100 transition-opacity">→</span>
                  <span>GitHub Discussions</span>
                </a>
              </li>
              <li>
                <a href="#" className="hover:text-green-400 transition-colors flex items-center gap-2 group">
                  <span className="opacity-0 group-hover:opacity-100 transition-opacity">→</span>
                  <span>Discord Server</span>
                </a>
              </li>
              <li>
                <a href="#" className="hover:text-green-400 transition-colors flex items-center gap-2 group">
                  <span className="opacity-0 group-hover:opacity-100 transition-opacity">→</span>
                  <span>Forum</span>
                </a>
              </li>
              <li>
                <a href="#" className="hover:text-green-400 transition-colors flex items-center gap-2 group">
                  <span className="opacity-0 group-hover:opacity-100 transition-opacity">→</span>
                  <span>Blog</span>
                </a>
              </li>
            </ul>
          </div> */}

                    {/* Resources Column */}
                    {/* <div>
            <h4 className="text-white mb-4 flex items-center gap-2">
              <span className="w-1 h-4 bg-purple-500 rounded-full" />
              Resources
            </h4>
            <ul className="space-y-3 text-sm">
              <li>
                <a href="#" className="hover:text-green-400 transition-colors flex items-center gap-2 group">
                  <span className="opacity-0 group-hover:opacity-100 transition-opacity">→</span>
                  <span>Roadmap</span>
                </a>
              </li>
              <li>
                <a href="#" className="hover:text-green-400 transition-colors flex items-center gap-2 group">
                  <span className="opacity-0 group-hover:opacity-100 transition-opacity">→</span>
                  <span>Changelog</span>
                </a>
              </li>
              <li>
                <a href="#" className="hover:text-green-400 transition-colors flex items-center gap-2 group">
                  <span className="opacity-0 group-hover:opacity-100 transition-opacity">→</span>
                  <span>Contributing</span>
                </a>
              </li>
              <li>
                <a href="#" className="hover:text-green-400 transition-colors flex items-center gap-2 group">
                  <span className="opacity-0 group-hover:opacity-100 transition-opacity">→</span>
                  <span>Brand Assets</span>
                </a>
              </li>
              <li>
                <a href="#" className="hover:text-green-400 transition-colors flex items-center gap-2 group">
                  <span className="opacity-0 group-hover:opacity-100 transition-opacity">→</span>
                  <span>Support</span>
                </a>
              </li>
            </ul>
          </div> */}
                </div>

                {/* Divider */}
                <div className="border-t border-gray-800 pt-8">
                    <div className="flex flex-col md:flex-row items-center justify-between gap-4">
                        {/* Copyright */}
                        <div className="flex items-center gap-2 text-sm">
                            <p className="text-gray-400">
                                © 2025 Jetleaf Framework. Built with
                            </p>
                            <Heart className="w-4 h-4 text-green-500 fill-green-500" />
                            <p className="text-gray-400">by Hapnium</p>
                        </div>

                        {/* Social Links */}
                        {/* <div className="flex items-center gap-4">
              <a 
                href="#" 
                className="p-2 rounded-lg bg-gray-800 hover:bg-gray-700 transition-colors group"
                aria-label="GitHub"
              >
                <Github className="w-5 h-5 text-gray-400 group-hover:text-white transition-colors" />
              </a>
              <a 
                href="#" 
                className="p-2 rounded-lg bg-gray-800 hover:bg-gray-700 transition-colors group"
                aria-label="Twitter"
              >
                <Twitter className="w-5 h-5 text-gray-400 group-hover:text-white transition-colors" />
              </a>
              <a 
                href="#" 
                className="p-2 rounded-lg bg-gray-800 hover:bg-gray-700 transition-colors group"
                aria-label="Discord"
              >
                <MessageCircle className="w-5 h-5 text-gray-400 group-hover:text-white transition-colors" />
              </a>
              <a 
                href="#" 
                className="p-2 rounded-lg bg-gray-800 hover:bg-gray-700 transition-colors group"
                aria-label="Email"
              >
                <Mail className="w-5 h-5 text-gray-400 group-hover:text-white transition-colors" />
              </a>
            </div> */}

                        {/* Legal Links */}
                        {/* <div className="flex items-center gap-4 text-sm">
              <a href="#" className="text-gray-400 hover:text-green-400 transition-colors">
                Privacy
              </a>
              <span className="text-gray-700">•</span>
              <a href="#" className="text-gray-400 hover:text-green-400 transition-colors">
                Terms
              </a>
              <span className="text-gray-700">•</span>
              <a href="#" className="text-gray-400 hover:text-green-400 transition-colors">
                License
              </a>
            </div> */}
                    </div>
                </div>
            </div>

            {/* Background decoration */}
            <div className="absolute bottom-0 right-0 w-1/3 h-1/2 opacity-5 pointer-events-none">
                <div className="absolute bottom-0 right-0 w-96 h-96 bg-green-500 rounded-full blur-3xl" />
            </div>
        </footer>
    );
}

/**
 * A React hook that highlights source code using the Shiki syntax highlighter.
 *
 * This hook converts raw code strings into HTML with syntax highlighting
 * according to the specified language and theme. It is designed for
 * rendering code snippets in React components safely and efficiently.
 *
 * ## Parameters
 * @param code {string}  
 *   The raw source code to be highlighted.
 *
 * @param lang {string}  
 *   The programming language of the source code. Defaults to `'dart'`.
 *   Shiki uses this to apply proper syntax coloring.
 *
 * @param theme {string}  
 *   The Shiki theme to apply for highlighting. Defaults to `'vitesse-dark'`.
 *   You can pass any theme supported by Shiki.
 *
 * ## Behavior
 * - The hook asynchronously transforms the `code` into HTML using `Shiki`.
 * - It updates the returned value whenever `code`, `lang`, or `theme` changes.
 * - The result is a string of HTML with syntax highlighting applied.
 *
 * ## Returns
 * @returns {string}  
 *   HTML string containing the highlighted code. This can be safely rendered
 *   in a React component using `dangerouslySetInnerHTML`.
 *
 * ## Example
 * ```tsx
 * const highlightedCode = useShiki('void main() => print("Hello");', 'dart', 'vitesse-dark');
 * return <pre dangerouslySetInnerHTML={{ __html: highlightedCode }} />;
 * ```
 */
function useShiki(code: string, lang: string = 'dart', theme: string = 'vitesse-dark'): string {
  const [html, setHtml] = useState<string>('')

  useEffect(() => {
    async function run() {
      const highlighted = await codeToHtml(code, {
        lang,
        theme
      })
      setHtml(highlighted)
    }
    run()
  }, [code, lang, theme])

  return html
}