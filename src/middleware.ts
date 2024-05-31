import { NextResponse } from "next/server";
import { NextRequest } from "next/server";

const PUBLIC_FILE = /\.(.*)$/;

export async function middleware(req: NextRequest) {
  const url = req.nextUrl.clone();

  if (PUBLIC_FILE.test(url.pathname) || url.pathname.includes("_next")) return;

  const host = req.headers.get("host")?.split(".") ?? [];
  if (host.length > 1) {
    const subdomain = host[0] ?? "localhost";
    if (subdomain && !subdomain.includes("localhost")) {
      console.log(`Rewriting: ${url.pathname} to /${subdomain}${url.pathname}`);
      url.pathname = `/${subdomain}${url.pathname}`;
    }
  }
  return NextResponse.rewrite(url);
}
