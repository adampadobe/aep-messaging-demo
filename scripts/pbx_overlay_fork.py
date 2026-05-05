#!/usr/bin/env python3
"""Merge fork-only MessagingDemoAppSwiftUI / Widget entries into upstream-based project.pbxproj."""
from __future__ import annotations

import re
import secrets
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PBX = ROOT / "AEPMessaging.xcodeproj" / "project.pbxproj"
FORK = Path("/tmp/pbx_fork.txt")


def nid() -> str:
    return secrets.token_hex(12).upper()


def main() -> None:
    u = PBX.read_text()
    fk = FORK.read_text()

    # --- PBXBuildFile: take fork lines for fork-specific sources (unique by fileRef id in comment)
    subs = (
        "Etihad", "Flynas", "KSIA", "TravelLiveActivityView", "TravelTheme", "TravelLogoCache",
        "TravelLiveActivity.swift in Sources", "IconManager", "SettingsView", "BrandSplash",
    )
    build_lines = []
    seen_ref: set[str] = set()
    for line in fk.splitlines():
        if "in Sources */ = {isa = PBXBuildFile" not in line:
            continue
        if not any(s in line for s in subs):
            continue
        m = re.search(r"fileRef = ([0-9A-F]+) /\*", line)
        if not m:
            continue
        if m.group(1) in seen_ref:
            continue
        seen_ref.add(m.group(1))
        build_lines.append(line)

    file_lines = []
    seen_fr: set[str] = set()
    for line in fk.splitlines():
        if "isa = PBXFileReference" not in line or "path = " not in line:
            continue
        if not any(s in line for s in subs + ("AlternateAppIcons", "WidgetMessagingDemoAppSwiftUI.entitlements")):
            continue
        m = re.search(r"^\t\t([0-9A-F]+) /\*", line)
        if not m:
            continue
        if m.group(1) in seen_fr:
            continue
        seen_fr.add(m.group(1))
        file_lines.append(line)

    res_build = next(
        l for l in fk.splitlines() if "AlternateAppIcons in Resources */ = {isa = PBXBuildFile" in l
    )

    for line in build_lines + [res_build]:
        if line not in u:
            u = u.replace("/* End PBXBuildFile section */", f"\t{line}\n/* End PBXBuildFile section */")

    for line in file_lines:
        if line not in u:
            u = u.replace("/* End PBXFileReference section */", f"\t{line}\n/* End PBXFileReference section */")

    branding_group = """\t\t08EB0632D9069876DF19680F /* Branding */ = {
			isa = PBXGroup;
			children = (
				C2ABBD2D86A79886A70B3BAD /* IconManager.swift */,
				3E42CB2890398C3622331448 /* SettingsView.swift */,
				C6F6E7A03938A7D729F1C8F1 /* BrandSplashView.swift */,
			);
			path = Branding;
			sourceTree = "<group>";
		};
"""
    if "08EB0632D9069876DF19680F /* Branding */" not in u:
        u = u.replace("/* End PBXGroup section */", f"{branding_group}/* End PBXGroup section */")

    # MessagingDemoAppSwiftUI root: AlternateAppIcons
    if "57183598A5D986323D4D0B59 /* AlternateAppIcons */" not in u:
        u = u.replace(
            "\t\t\t\t0969D6D02A7AFB3800A00BF7 /* Preview Content */,\n\t\t\t);",
            "\t\t\t\t0969D6D02A7AFB3800A00BF7 /* Preview Content */,\n"
            "\t\t\t\t57183598A5D986323D4D0B59 /* AlternateAppIcons */,\n"
            "\t\t\t);",
            1,
        )

    # AppPages: InboxView already; append Branding
    if "08EB0632D9069876DF19680F /* Branding */" in u and "B6F7CC932CC80E2800C35C64 /* AppPages */" in u:
        marker = "\t\t\t\t092A77F12A757CB40026D325 /* CodeBasedView.swift */,\n\t\t\t);"
        replacement = (
            "\t\t\t\t092A77F12A757CB40026D325 /* CodeBasedView.swift */,\n"
            "\t\t\t\t08EB0632D9069876DF19680F /* Branding */,\n"
            "\t\t\t);"
        )
        if marker in u and "08EB0632D9069876DF19680F /* Branding */,\n\t\t\t);" not in u:
            u = u.replace(marker, replacement, 1)

    # Attributes
    old_a = (
        "\t\t\tchildren = (\n"
        "\t\t\t\tB61BD8D72DA466F9007FE12E /* AirplaneTrackingAttributes.swift */,\n"
        "\t\t\t\tB61BD8D82DA466F9007FE12E /* FoodDeliveryLiveActivityAttributes.swift */,\n"
        "\t\t\t\tB61BD8D92DA466F9007FE12E /* GameScoreLiveActivityAttributes.swift */,\n"
        "\t\t\t);\n"
        "\t\t\tpath = Attributes;"
    )
    new_a = (
        "\t\t\tchildren = (\n"
        "\t\t\t\tB61BD8D72DA466F9007FE12E /* AirplaneTrackingAttributes.swift */,\n"
        "\t\t\t\tB61BD8D82DA466F9007FE12E /* FoodDeliveryLiveActivityAttributes.swift */,\n"
        "\t\t\t\tB61BD8D92DA466F9007FE12E /* GameScoreLiveActivityAttributes.swift */,\n"
        "\t\t\t\t5760AF6F1BFF05AFEAF1F8E2 /* EtihadPremiumFlightAttributes.swift */,\n"
        "\t\t\t\tECD83A2D350B0FE2A8177D8C /* EtihadBoardingAttributes.swift */,\n"
        "\t\t\t\tD81E7F07946CF38A6D273421 /* KSIAAirportAttributes.swift */,\n"
        "\t\t\t\t145E8C0CC8F53B5E00EA1D50 /* FlynasFlightAttributes.swift */,\n"
        "\t\t\t\tA7CA43E1EBEABAA1056A0C2D /* TravelLiveActivityAttributes.swift */,\n"
        "\t\t\t);\n"
        "\t\t\tpath = Attributes;"
    )
    if old_a in u:
        u = u.replace(old_a, new_a, 1)

    old_p = (
        "\t\t\tchildren = (\n"
        "\t\t\t\tB61BD8DB2DA466F9007FE12E /* AirplaneTrackingLiveActivityView.swift */,\n"
        "\t\t\t\tB61BD8DC2DA466F9007FE12E /* CommonLiveActivityViews.swift */,\n"
        "\t\t\t\tB61BD8DD2DA466F9007FE12E /* FoodDeliveryLiveActivityView.swift */,\n"
        "\t\t\t\tB61BD8DE2DA466F9007FE12E /* GameScoreLiveActivityView.swift */,\n"
        "\t\t\t);\n"
        "\t\t\tpath = Pages;"
    )
    new_p = (
        "\t\t\tchildren = (\n"
        "\t\t\t\tB61BD8DB2DA466F9007FE12E /* AirplaneTrackingLiveActivityView.swift */,\n"
        "\t\t\t\tB61BD8DC2DA466F9007FE12E /* CommonLiveActivityViews.swift */,\n"
        "\t\t\t\tB61BD8DD2DA466F9007FE12E /* FoodDeliveryLiveActivityView.swift */,\n"
        "\t\t\t\tB61BD8DE2DA466F9007FE12E /* GameScoreLiveActivityView.swift */,\n"
        "\t\t\t\tB2A548464C27C249C6FB3777 /* EtihadPremiumLiveActivityView.swift */,\n"
        "\t\t\t\t910478188AACAB204271B79F /* EtihadBoardingLiveActivityView.swift */,\n"
        "\t\t\t\t0DAFE600BE7E6E28C762499F /* KSIAAirportLiveActivityView.swift */,\n"
        "\t\t\t\t618D4DF06F1B5D60B6026813 /* FlynasLiveActivityView.swift */,\n"
        "\t\t\t\tC19F021847D76A2B78E63FBF /* TravelLiveActivityView.swift */,\n"
        "\t\t\t);\n"
        "\t\t\tpath = Pages;"
    )
    if old_p in u:
        u = u.replace(old_p, new_p, 1)

    travel_group_id = nid()
    travel_group = (
        f"\t\t{travel_group_id} /* Travel */ = {{\n"
        "\t\t\tisa = PBXGroup;\n"
        "\t\t\tchildren = (\n"
        "\t\t\t\t2E5CFABC0872253EB73E7F7A /* TravelTheme.swift */,\n"
        "\t\t\t\tB787D3AEC0B4FCFC639C3C59 /* TravelLogoCache.swift */,\n"
        "\t\t\t);\n"
        "\t\t\tpath = Travel;\n"
        '\t\t\tsourceTree = "<group>";\n'
        "\t\t};\n"
    )
    if "2E5CFABC0872253EB73E7F7A /* TravelTheme.swift */" not in u:
        u = u.replace("/* End PBXGroup section */", f"{travel_group}/* End PBXGroup section */")
        u = u.replace(
            "\t\t\t\tB61BD8DF2DA466F9007FE12E /* Pages */,\n"
            "\t\t\t);\n"
            "\t\t\tpath = LiveActivity;",
            f"\t\t\t\tB61BD8DF2DA466F9007FE12E /* Pages */,\n"
            f"\t\t\t\t{travel_group_id} /* Travel */,\n"
            f"\t\t\t);\n"
            f"\t\t\tpath = LiveActivity;",
            1,
        )

    # Widget LiveActivityUI: add EtihadBoarding, EtihadPremium, Flynas, KSIA, Travel groups
    gid_eb, gid_ep, gid_fn, gid_ks, gid_tr = nid(), nid(), nid(), nid(), nid()
    widget_groups = (
        f"\t\t{gid_eb} /* EtihadBoarding */ = {{\n"
        "\t\t\tisa = PBXGroup;\n"
        "\t\t\tchildren = (\n"
        "\t\t\t\tC5A23F8317AAEBB040AE268E /* EtihadBoardingLiveActivity.swift */,\n"
        "\t\t\t);\n"
        "\t\t\tpath = EtihadBoarding;\n"
        '\t\t\tsourceTree = "<group>";\n'
        "\t\t};\n"
        f"\t\t{gid_ep} /* EtihadPremium */ = {{\n"
        "\t\t\tisa = PBXGroup;\n"
        "\t\t\tchildren = (\n"
        "\t\t\t\t51E066FE4BB8537A3C75AB19 /* EtihadPremiumLiveActivity.swift */,\n"
        "\t\t\t);\n"
        "\t\t\tpath = EtihadPremium;\n"
        '\t\t\tsourceTree = "<group>";\n'
        "\t\t};\n"
        f"\t\t{gid_fn} /* Flynas */ = {{\n"
        "\t\t\tisa = PBXGroup;\n"
        "\t\t\tchildren = (\n"
        "\t\t\t\t83CD8FD8C205713EB5600256 /* FlynasLiveActivity.swift */,\n"
        "\t\t\t);\n"
        "\t\t\tpath = Flynas;\n"
        '\t\t\tsourceTree = "<group>";\n'
        "\t\t};\n"
        f"\t\t{gid_ks} /* KSIA */ = {{\n"
        "\t\t\tisa = PBXGroup;\n"
        "\t\t\tchildren = (\n"
        "\t\t\t\t52483DA0910210F689F70B4A /* KSIAAirportLiveActivity.swift */,\n"
        "\t\t\t);\n"
        "\t\t\tpath = KSIA;\n"
        '\t\t\tsourceTree = "<group>";\n'
        "\t\t};\n"
        f"\t\t{gid_tr} /* Travel */ = {{\n"
        "\t\t\tisa = PBXGroup;\n"
        "\t\t\tchildren = (\n"
        "\t\t\t\tA05D1D495CAAE6850732D467 /* TravelLiveActivity.swift */,\n"
        "\t\t\t);\n"
        "\t\t\tpath = Travel;\n"
        '\t\t\tsourceTree = "<group>";\n'
        "\t\t};\n"
    )
    if "path = EtihadBoarding;" not in u:
        u = u.replace("/* End PBXGroup section */", f"{widget_groups}\n/* End PBXGroup section */")
        old_laui = (
            "\t\t\tchildren = (\n"
            "\t\t\t\tB61BD9C22DA4BD16007FE12E /* AirplaneTracker */,\n"
            "\t\t\t\tB61BD9C52DA4BD16007FE12E /* FoodDelivery */,\n"
            "\t\t\t\tB61BD9C72DA4BD16007FE12E /* Game */,\n"
            "\t\t\t);\n"
            "\t\t\tpath = LiveActivityUI;"
        )
        new_laui = (
            "\t\t\tchildren = (\n"
            "\t\t\t\tB61BD9C22DA4BD16007FE12E /* AirplaneTracker */,\n"
            "\t\t\t\tB61BD9C52DA4BD16007FE12E /* FoodDelivery */,\n"
            "\t\t\t\tB61BD9C72DA4BD16007FE12E /* Game */,\n"
            f"\t\t\t\t{gid_eb} /* EtihadBoarding */,\n"
            f"\t\t\t\t{gid_ep} /* EtihadPremium */,\n"
            f"\t\t\t\t{gid_fn} /* Flynas */,\n"
            f"\t\t\t\t{gid_ks} /* KSIA */,\n"
            f"\t\t\t\t{gid_tr} /* Travel */,\n"
            "\t\t\t);\n"
            "\t\t\tpath = LiveActivityUI;"
        )
        if old_laui in u:
            u = u.replace(old_laui, new_laui, 1)

    # Widget group: entitlements ref (optional for Xcode tree)
    if "F44625E12F29AA20A221131C /* WidgetMessagingDemoAppSwiftUI.entitlements */" not in u:
        u = u.replace(
            "\t\t\t\tB61BD9CB2DA4BD16007FE12E /* WidgetMessagingDemoAppSwiftUIBundle.swift */,\n"
            "\t\t\t);\n"
            "\t\t\tname = WidgetMessagingDemoAppSwiftUI;",
            "\t\t\t\tB61BD9CB2DA4BD16007FE12E /* WidgetMessagingDemoAppSwiftUIBundle.swift */,\n"
            "\t\t\t\tF44625E12F29AA20A221131C /* WidgetMessagingDemoAppSwiftUI.entitlements */,\n"
            "\t\t\t);\n"
            "\t\t\tname = WidgetMessagingDemoAppSwiftUI;",
            1,
        )

    # MessagingDemoAppSwiftUI Sources: insert fork-only compile lines before closing );
    demo_src_anchor = "\t\t\t\t091881E72A16BAE300615481 /* MessagingDemoAppSwiftUIApp.swift in Sources */,\n\t\t\t);"
    insert_demo = """\t\t\t\t091881E72A16BAE300615481 /* MessagingDemoAppSwiftUIApp.swift in Sources */,
				EB32695532003551BAEF8D43 /* EtihadPremiumFlightAttributes.swift in Sources */,
				94EC73CAA8156458D6E6D8E4 /* EtihadPremiumLiveActivityView.swift in Sources */,
				AB1194E3533C5CF3534A3AD0 /* EtihadBoardingAttributes.swift in Sources */,
				D99551ACFA0CCD0A03EC6E65 /* EtihadBoardingLiveActivityView.swift in Sources */,
				00CDF3D4D87662219C693956 /* KSIAAirportAttributes.swift in Sources */,
				AE619CED1A055657E7500525 /* KSIAAirportLiveActivityView.swift in Sources */,
				78FD7BC272965BF4DB6FC38C /* FlynasFlightAttributes.swift in Sources */,
				2C13BE0755C549F8916762D7 /* FlynasLiveActivityView.swift in Sources */,
				B27ABE633636E5723829A952 /* TravelLiveActivityAttributes.swift in Sources */,
				836EB2A76866A5DD56A4C12C /* TravelLogoCache.swift in Sources */,
				FD180BD99D2E10A20980FEEE /* TravelTheme.swift in Sources */,
				2EFB232F65D8A5892B4A0B16 /* TravelLiveActivityView.swift in Sources */,
				20E8842AE3C1271C39F08AFC /* IconManager.swift in Sources */,
				F6BE0B4A2A58D647AB827D51 /* SettingsView.swift in Sources */,
				418AECF9E7821B215041459C /* BrandSplashView.swift in Sources */,
			);"""
    if "418AECF9E7821B215041459C /* BrandSplashView.swift in Sources */" not in u and demo_src_anchor in u:
        u = u.replace(demo_src_anchor, insert_demo, 1)

    # Widget extension Sources
    w_src_anchor = (
        "\t\t\t\tB61BD9D32DA4BD16007FE12E /* WidgetMessagingDemoAppSwiftUIBundle.swift in Sources */,\n"
        "\t\t\t);\n"
        "\t\t\trunOnlyForDeploymentPostprocessing = 0;\n"
        "\t\t};\n"
        "\t\tB61BDAB12DA5E826007FE12E /* Sources */ = {"
    )
    insert_w = (
        "\t\t\t\tB61BD9D32DA4BD16007FE12E /* WidgetMessagingDemoAppSwiftUIBundle.swift in Sources */,\n"
        "\t\t\t\tE007C689D5284E70870F8211 /* EtihadPremiumLiveActivity.swift in Sources */,\n"
        "\t\t\t\tE2F15A5C1B92033400A07D85 /* EtihadBoardingLiveActivity.swift in Sources */,\n"
        "\t\t\t\tEFE8E9849129D03F63D6FB55 /* KSIAAirportLiveActivity.swift in Sources */,\n"
        "\t\t\t\tC33C9363425C661D4CB058CB /* FlynasLiveActivity.swift in Sources */,\n"
        "\t\t\t\t087093B1FFADC7F5B680F77F /* TravelLiveActivity.swift in Sources */,\n"
        "\t\t\t);\n"
        "\t\t\trunOnlyForDeploymentPostprocessing = 0;\n"
        "\t\t};\n"
        "\t\tB61BDAB12DA5E826007FE12E /* Sources */ = {"
    )
    if "087093B1FFADC7F5B680F77F /* TravelLiveActivity.swift in Sources */" not in u and w_src_anchor in u:
        u = u.replace(w_src_anchor, insert_w, 1)

    # Resources: AlternateAppIcons
    res_anchor = (
        "\t\t\tfiles = (\n"
        "\t\t\t\t0969D6D12A7AFB3800A00BF7 /* Preview Content in Resources */,\n"
        "\t\t\t\t091881EB2A16BAE400615481 /* Assets.xcassets in Resources */,\n"
        "\t\t\t);\n"
        "\t\t\trunOnlyForDeploymentPostprocessing = 0;\n"
        "\t\t};\n"
        "\t\t1141D03E1BCAD127D569FBD5 /* Resources */ = {"
    )
    insert_res = (
        "\t\t\tfiles = (\n"
        "\t\t\t\t0969D6D12A7AFB3800A00BF7 /* Preview Content in Resources */,\n"
        "\t\t\t\t091881EB2A16BAE400615481 /* Assets.xcassets in Resources */,\n"
        "\t\t\t\t82E3F0922C539BA4DE00BE85 /* AlternateAppIcons in Resources */,\n"
        "\t\t\t);\n"
        "\t\t\trunOnlyForDeploymentPostprocessing = 0;\n"
        "\t\t};\n"
        "\t\t1141D03E1BCAD127D569FBD5 /* Resources */ = {"
    )
    if "82E3F0922C539BA4DE00BE85 /* AlternateAppIcons in Resources */" not in u and res_anchor in u:
        u = u.replace(res_anchor, insert_res, 1)

    PBX.write_text(u)
    print("Wrote", PBX)


if __name__ == "__main__":
    main()
