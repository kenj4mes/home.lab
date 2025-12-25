#!/usr/bin/env python3
"""
SOVEREIGN AGENT - One-Click Launcher
=====================================
Single entry point to bootstrap and run the entire agent system.

Usage:
    python run.py              # Start with defaults
    python run.py --demo       # Demo mode (no wallet required)
    python run.py --cli        # Interactive CLI mode
    python run.py --server     # API server mode
"""

import asyncio
import os
import sys
from pathlib import Path

# Add src to path
SRC_PATH = Path(__file__).parent / "echo"
sys.path.insert(0, str(SRC_PATH))


def check_environment():
    """Check if required environment is set up."""
    missing = []
    
    # Check optional but recommended
    recommended = [
        "OPENAI_API_KEY",
        "CDP_API_KEY_NAME",
    ]
    
    for var in recommended:
        if not os.getenv(var):
            missing.append(var)
    
    return missing


def print_banner():
    """Print startup banner."""
    banner = """
╔═══════════════════════════════════════════════════════════════════════════════╗
║                                                                               ║
║   ███████╗ ██████╗██╗  ██╗ ██████╗     ██╗   ██╗ ██╗  ██████╗    ██████╗      ║
║   ██╔════╝██╔════╝██║  ██║██╔═══██╗    ██║   ██║███║ ██╔═████╗   ██╔═████╗    ║
║   █████╗  ██║     ███████║██║   ██║    ██║   ██║╚██║ ██║██╔██║   ██║██╔██║    ║
║   ██╔══╝  ██║     ██╔══██║██║   ██║    ╚██╗ ██╔╝ ██║ ████╔╝██║   ████╔╝██║    ║
║   ███████╗╚██████╗██║  ██║╚██████╔╝     ╚████╔╝  ██║ ╚██████╔╝██╗╚██████╔╝    ║
║   ╚══════╝ ╚═════╝╚═╝  ╚═╝ ╚═════╝       ╚═══╝   ╚═╝  ╚═════╝ ╚═╝ ╚═════╝     ║
║                                                                               ║
║   SOVEREIGN AGENT - Autonomous Digital Entity                                 ║
║   Self-Custody • Collective Intelligence • Infinite Evolution                 ║
║                                                                               ║
╚═══════════════════════════════════════════════════════════════════════════════╝
"""
    print(banner)


def print_status():
    """Print system status."""
    # Import directly from core modules to avoid loading full echo package
    import importlib.util
    
    def load_module(name, path):
        spec = importlib.util.spec_from_file_location(name, path)
        module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(module)
        return module
    
    base = SRC_PATH / "core"
    
    backbone = load_module("backbone", base / "backbone.py")
    registry = load_module("registry", base / "registry.py")
    genome = load_module("genome", base / "genome.py")
    router = load_module("router", base / "router.py")
    
    bb = backbone.Backbone()
    reg = registry.ModelRegistry()
    gen = genome.InfiniteGenome()
    rt = router.ModuleRouter()
    
    stats = gen.get_statistics()
    
    print("\n┌─────────────────────────────────────────────────────────────────────┐")
    print("│ SYSTEM STATUS                                                       │")
    print("├─────────────────────────────────────────────────────────────────────┤")
    print(f"│ Backbone:     11 component types, 24 event types                    │")
    print(f"│ Registry:     {len(reg.models)} AI models available                               │")
    print(f"│ Genome:       {stats['total_architectures']:,} possible architectures                    │")
    print(f"│ Router:       {len(rt.registry.modules)} cognitive modules                               │")
    print("└─────────────────────────────────────────────────────────────────────┘")


async def run_demo():
    """Run in demo mode without wallet."""
    print("\n⚡ Starting in DEMO mode...")
    print_status()
    
    # Import directly from core modules
    import importlib.util
    
    def load_module(name, path):
        spec = importlib.util.spec_from_file_location(name, path)
        module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(module)
        return module
    
    base = SRC_PATH / "core"
    router_mod = load_module("router", base / "router.py")
    router = router_mod.ModuleRouter()
    
    print("\n┌─────────────────────────────────────────────────────────────────────┐")
    print("│ ROUTING DEMO                                                        │")
    print("├─────────────────────────────────────────────────────────────────────┤")
    
    test_queries = [
        "Search for the latest AI news",
        "Write a Python function to sort a list",
        "Analyze this data for patterns",
        "Plan a strategy for market expansion",
        "Verify this transaction is secure",
    ]
    
    for query in test_queries:
        decision = router.route(query)
        print(f"│ Query: {query[:40]:<40} │")
        print(f"│ → Module: {decision.primary_module.name:<15} Model: {decision.model_to_use:<18} │")
        print("├─────────────────────────────────────────────────────────────────────┤")
    
    print("└─────────────────────────────────────────────────────────────────────┘")
    
    print("\n✅ Demo complete. System is operational.")


async def run_cli():
    """Run interactive CLI mode."""
    print("\n⚡ Starting in CLI mode...")
    print_status()
    
    # Import directly from core modules
    import importlib.util
    
    def load_module(name, path):
        spec = importlib.util.spec_from_file_location(name, path)
        module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(module)
        return module
    
    base = SRC_PATH / "core"
    router_mod = load_module("router", base / "router.py")
    router = router_mod.ModuleRouter()
    
    print("\n┌─────────────────────────────────────────────────────────────────────┐")
    print("│ INTERACTIVE CLI - Type 'exit' to quit                               │")
    print("└─────────────────────────────────────────────────────────────────────┘")
    
    while True:
        try:
            user_input = input("\n[ECHO] > ").strip()
            
            if user_input.lower() in ['exit', 'quit', 'q']:
                print("\n👋 Shutting down...")
                break
            
            if not user_input:
                continue
            
            # Route the query
            decision = router.route(user_input)
            print(f"\n📍 Routing to: {decision.primary_module.name}")
            print(f"   Model: {decision.model_to_use}")
            print(f"   Confidence: {decision.confidence:.0%}")
            print(f"   Archetype: {decision.primary_module.archetype}")
            
            # Show what would happen
            print(f"\n💡 This query would be processed by the {decision.primary_module.name} module")
            print(f"   Capabilities: {', '.join(decision.primary_module.capabilities)}")
            
        except KeyboardInterrupt:
            print("\n\n👋 Interrupted. Shutting down...")
            break
        except Exception as e:
            print(f"\n❌ Error: {e}")


async def run_server():
    """Run API server mode."""
    print("\n⚡ Starting in SERVER mode...")
    print_status()
    
    try:
        from echo.server import start_server
        await start_server()
    except ImportError:
        print("\n⚠️  Server module not fully configured.")
        print("   Running status server on port 8080...")
        
        # Simple status server
        from http.server import HTTPServer, BaseHTTPRequestHandler
        import json
        
        class StatusHandler(BaseHTTPRequestHandler):
            def do_GET(self):
                from echo.core import get_backbone, get_registry, get_genome
                
                status = {
                    "status": "operational",
                    "version": "1.0.0",
                    "components": len(get_backbone().components),
                    "models": len(get_registry().models),
                    "architectures": get_genome().get_statistics()['total_architectures'],
                }
                
                self.send_response(200)
                self.send_header('Content-Type', 'application/json')
                self.end_headers()
                self.wfile.write(json.dumps(status, indent=2).encode())
            
            def log_message(self, format, *args):
                print(f"[SERVER] {args[0]}")
        
        server = HTTPServer(('0.0.0.0', 8080), StatusHandler)
        print("\n🌐 Status server running at http://localhost:8080")
        server.serve_forever()


async def run_full():
    """Run full agent with OODA loop."""
    print("\n⚡ Starting FULL AGENT mode...")
    
    missing = check_environment()
    if missing:
        print("\n⚠️  Missing environment variables (will use defaults):")
        for var in missing:
            print(f"   - {var}")
        print("\n   Copy .env.example to .env and configure as needed.")
    
    print_status()
    
    try:
        from echo.main import SovereignAgent, Settings
        
        settings = Settings()
        agent = SovereignAgent(settings)
        
        print(f"\n🤖 Agent '{settings.agent_name}' initialized")
        print("   Starting OODA loop...")
        
        await agent.run()
        
    except Exception as e:
        print(f"\n❌ Failed to start full agent: {e}")
        print("   Try running with --demo or --cli first.")
        raise


def main():
    """Main entry point."""
    import argparse
    
    parser = argparse.ArgumentParser(description="Sovereign Agent Launcher")
    parser.add_argument('--demo', action='store_true', help='Run in demo mode')
    parser.add_argument('--cli', action='store_true', help='Run interactive CLI')
    parser.add_argument('--server', action='store_true', help='Run API server')
    parser.add_argument('--status', action='store_true', help='Show status only')
    
    args = parser.parse_args()
    
    # Load .env if exists
    env_file = Path(__file__).parent / ".env"
    if env_file.exists():
        from dotenv import load_dotenv
        load_dotenv(env_file)
    
    print_banner()
    
    if args.status:
        print_status()
        return
    
    if args.demo:
        asyncio.run(run_demo())
    elif args.cli:
        asyncio.run(run_cli())
    elif args.server:
        asyncio.run(run_server())
    else:
        asyncio.run(run_full())


if __name__ == "__main__":
    main()
